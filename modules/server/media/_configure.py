"""Converges the media stack to the settings in configure.nix, through each app's own API.

Run as root by media-configure.service with a JSON config as its only argument. Every step reads
the current state first and only writes what differs, so it is safe to run again at any time. It
creates and fixes what the config names and deletes only what it replaced.
"""

import base64
import hashlib
import http.cookiejar
import json
import os
import secrets
import sqlite3
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

import yaml

cfg = json.load(open(sys.argv[1]))
failed = []


def log(msg):
    print(msg, flush=True)


def read(path):
    with open(path) as f:
        return f.read().strip()


class Api:
    """JSON over HTTP with fixed headers, or a cookie session."""

    def __init__(self, base, headers=None, cookies=False):
        self.base = base.rstrip("/")
        self.headers = headers or {}
        handlers = [urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar())] if cookies else []
        self.opener = urllib.request.build_opener(*handlers)

    def call(self, method, path, body=None, form=None, ok=(200, 201, 202, 204)):
        headers = dict(self.headers)
        data = None
        if form is not None:
            data = urllib.parse.urlencode(form, doseq=True).encode()
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        elif body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(self.base + path, data=data, headers=headers, method=method)
        try:
            with self.opener.open(req, timeout=120) as r:
                status, text = r.status, r.read().decode()
        except urllib.error.HTTPError as e:
            status, text = e.code, e.read().decode(errors="replace")
        if status not in ok:
            raise RuntimeError(f"{method} {path}: HTTP {status}: {text[:300]}")
        try:
            return json.loads(text) if text else None
        except ValueError:
            return text

    def get(self, path, **kw):
        return self.call("GET", path, **kw)

    def post(self, path, body=None, **kw):
        return self.call("POST", path, body, **kw)

    def put(self, path, body=None, **kw):
        return self.call("PUT", path, body, **kw)

    def wait(self, path, minutes=5):
        """Until the app answers at all; it may still be migrating its database on first start."""
        end = time.time() + minutes * 60
        while True:
            try:
                return self.call("GET", path, ok=range(200, 500))
            except (OSError, RuntimeError) as e:
                if time.time() > end:
                    raise RuntimeError(f"{self.base} did not come up: {e}")
                time.sleep(3)


def step(name, fn, *args):
    try:
        log(f"== {name}")
        return fn(*args)
    except Exception as e:  # noqa: BLE001  one broken app must not stop the others
        log(f"!! {name} failed: {e}")
        failed.append(name)


def systemctl(*args):
    if cfg.get("systemctl", True):
        subprocess.run(["systemctl", *args], check=True)


# Servarr fields are a list of {name, value}; these read and set them by name.
def field(item, name):
    return next((f.get("value") for f in item["fields"] if f["name"] == name), None)


def set_fields(item, values):
    changed = False
    for f in item["fields"]:
        if f["name"] in values and f.get("value") != values[f["name"]]:
            f["value"] = values[f["name"]]
            changed = True
    return changed


def from_schema(api, kind, implementation):
    return next(s for s in api.get(f"/{kind}/schema") if s["implementation"] == implementation)


# ---------------------------------------------------------------------------------------- keys


def arr_key(name):
    return ET.parse(cfg[name]["configFile"]).getroot().findtext("ApiKey")


def keys():
    """Each app made its own API key on first start; the others get it from there."""
    k = {name: arr_key(name) for name in ("sonarr", "radarr", "prowlarr")}
    k["bazarr"] = yaml.safe_load(open(cfg["bazarr"]["configFile"]))["auth"]["apikey"]
    # Recyclarr reads these through LoadCredential (recyclarr.nix).
    os.makedirs(cfg["keysDir"], mode=0o700, exist_ok=True)
    for name in ("sonarr", "radarr"):
        path = os.path.join(cfg["keysDir"], name)
        if not os.path.exists(path) or read(path) != k[name]:
            with open(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
                f.write(k[name])
    return k


# ------------------------------------------------------------------------------------ jellyfin


def jellyfin_key(c):
    """An API key straight in Jellyfin's database. It only loads keys at startup, so a new one
    means a restart, once."""
    db = c["db"]
    st = os.stat(db)
    with sqlite3.connect(db) as con:
        row = con.execute("SELECT AccessToken FROM ApiKeys WHERE Name = 'media-configure'").fetchone()
    if row:
        return row[0]
    token = secrets.token_hex(16)
    systemctl("stop", "jellyfin.service")
    with sqlite3.connect(db) as con:
        con.execute(
            "INSERT INTO ApiKeys (DateCreated, DateLastActivity, Name, AccessToken) "
            "VALUES (datetime('now'), datetime('now'), 'media-configure', ?)",
            (token,),
        )
    con.close()
    # Written as root; Jellyfin must still own the journal files.
    for suffix in ("", "-wal", "-shm", "-journal"):
        if os.path.exists(db + suffix):
            os.chown(db + suffix, st.st_uid, st.st_gid)
    systemctl("start", "jellyfin.service")
    log("created Jellyfin API key")
    return token


def jellyfin(c):
    anon = Api(c["url"], {"Authorization": 'MediaBrowser Client="media-configure", Device="nixos", DeviceId="media-configure", Version="1"'})
    info = anon.wait("/System/Info/Public")
    if not info.get("StartupWizardCompleted"):
        admin = c["users"][0]
        anon.post("/Startup/Configuration", {"UICulture": "en-US", "MetadataCountryCode": c["country"], "PreferredMetadataLanguage": c["metadataLanguage"]})
        anon.get("/Startup/User")
        anon.post("/Startup/User", {"Name": admin["name"], "Password": read(admin["passwordFile"])})
        anon.post("/Startup/Complete")
        log(f"finished the setup wizard with {admin['name']} as admin")

    token = jellyfin_key(c)
    api = Api(c["url"], {"Authorization": f'MediaBrowser Token="{token}"'})
    api.wait("/System/Info/Public")
    for _ in range(60):  # the key works once startup is done
        try:
            api.get("/System/Configuration")
            break
        except RuntimeError:
            time.sleep(3)

    conf = api.get("/System/Configuration")
    want = {"ServerName": c["serverName"], "PreferredMetadataLanguage": c["metadataLanguage"], "MetadataCountryCode": c["country"]}
    if any(conf.get(k) != v for k, v in want.items()):
        api.post("/System/Configuration", {**conf, **want})
        log(f"server settings: {want}")

    folders = api.get("/Library/VirtualFolders")
    for lib in c["libraries"]:
        if any(lib["path"] in f.get("Locations", []) for f in folders):
            continue
        q = urllib.parse.urlencode({"name": lib["name"], "collectionType": lib["type"], "refreshLibrary": "true"})
        api.post(f"/Library/VirtualFolders?{q}", {"LibraryOptions": {"EnableRealtimeMonitor": True, "PathInfos": [{"Path": lib["path"]}], **c["libraryOptions"]}})
        log(f"added library {lib['name']} at {lib['path']}")
    for f in api.get("/Library/VirtualFolders"):
        opts = f.get("LibraryOptions") or {}
        if any(opts.get(k) != v for k, v in c["libraryOptions"].items()):
            api.post("/Library/VirtualFolders/LibraryOptions", {"Id": f["ItemId"], "LibraryOptions": {**opts, **c["libraryOptions"]}})
            log(f"library {f['Name']}: {c['libraryOptions']}")
    library_fetchers(api, c)

    users = {u["Name"]: u for u in api.get("/Users")}
    for u in c["users"]:
        if u["name"] not in users:
            users[u["name"]] = api.post("/Users/New", {"Name": u["name"], "Password": read(u["passwordFile"])})
            log(f"created user {u['name']}")
        user = api.get(f"/Users/{users[u['name']]['Id']}")
        if user["Policy"]["IsAdministrator"] != u["admin"]:
            api.post(f"/Users/{user['Id']}/Policy", {**user["Policy"], "IsAdministrator": u["admin"]})
            log(f"{u['name']}: admin = {u['admin']}")
        prefs = user["Configuration"]
        if any(prefs.get(k) != v for k, v in c["playback"].items()):
            api.post(f"/Users/{user['Id']}/Configuration", {**prefs, **c["playback"]})
            log(f"{u['name']}: playback {c['playback']}")
    return token


def library_fetchers(api, c):
    """Metadata and image sources per item type: Gelato first, so its titles get their metadata from
    the addon; no Screen Grabber, which would read every file from Real-Debrid for a thumbnail."""
    for f in api.get("/Library/VirtualFolders"):
        kind = {"movies": "movies", "tvshows": "tvshows"}.get(f.get("CollectionType"))
        if not kind:
            continue
        available = api.get(f"/Libraries/AvailableOptions?libraryContentType={kind}")["TypeOptions"]
        want = []
        for t in available:
            def names(key):
                n = [x["Name"] for x in t[key] if x["DefaultEnabled"] and x["Name"] not in c["disabledFetchers"]]
                return sorted(n, key=lambda name: name != "Gelato")
            meta, images = names("MetadataFetchers"), names("ImageFetchers")
            want.append({"Type": t["Type"], "MetadataFetchers": meta, "MetadataFetcherOrder": meta, "ImageFetchers": images, "ImageFetcherOrder": images, "ImageOptions": []})
        opts = f.get("LibraryOptions") or {}
        have = {t["Type"]: t for t in opts.get("TypeOptions") or []}
        keys = ("MetadataFetchers", "MetadataFetcherOrder", "ImageFetchers", "ImageFetcherOrder")
        if any(have.get(t["Type"], {}).get(k) != t[k] for t in want for k in keys):
            merged = [{**t, **have.get(t["Type"], {}), **{k: t[k] for k in keys}} for t in want]
            api.post("/Library/VirtualFolders/LibraryOptions", {"Id": f["ItemId"], "LibraryOptions": {**opts, "TypeOptions": merged}})
            log(f"library {f['Name']}: metadata and image sources {[t['Type'] for t in want]}")


# ----------------------------------------------------------------------------------- aiostreams


def aiostreams(c):
    """One AIOStreams user holds the addon setup Gelato uses. Its uuid and password live in
    media-configure's state, as AIOStreams can't give either back."""
    api = Api(c["url"] + "/api/v1")
    api.wait("/status")
    config = json.load(open(c["configFile"]))
    digest = hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest()
    state_file = os.path.join(cfg["keysDir"], "aiostreams.json")
    state = json.load(open(state_file)) if os.path.exists(state_file) else None

    if state:
        api.headers["Authorization"] = "Basic " + base64.b64encode(f"{state['uuid']}:{state['password']}".encode()).decode()
        # Kept from creation: it comes back different on every call, and Gelato's URL holds it.
        try:
            api.get("/user")
        except RuntimeError as e:
            # Its database or secret key is gone; a new user it is.
            log(f"AIOStreams user {state['uuid']} unusable ({str(e)[:100]}), making a new one")
            state = None
            del api.headers["Authorization"]

    if not state:
        password = secrets.token_hex(24)
        data = api.post("/user", {"config": config, "password": password})["data"]
        state = {"uuid": data["uuid"], "password": password, "encryptedPassword": data["encryptedPassword"], "digest": digest}
        log(f"created AIOStreams user {state['uuid']}")
    elif state.get("digest") != digest:
        api.put("/user", {"config": config})
        state["digest"] = digest
        log("AIOStreams config updated")

    with open(os.open(state_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
        json.dump(state, f)
    return f"{c['url']}/stremio/{state['uuid']}/{state['encryptedPassword']}/manifest.json"


# --------------------------------------------------------------------------------------- gelato


def gelato(c, jf_key, manifest):
    api = Api(cfg["jellyfin"]["url"], {"Authorization": f'MediaBrowser Token="{jf_key}"'})
    path = f"/Plugins/{c['pluginId']}/Configuration"
    have = api.get(path)

    # The addon's catalogs that fill the home screen; Gelato imports them on a schedule. Their ids
    # change with the addon setup, so the list is replaced, keeping the settings of those it had.
    known = {(x["Id"], x["Type"]): x for x in have.get("Catalogs") or []}
    catalogs = [
        {**known.get((cat["id"], cat["type"]), {}), "Id": cat["id"], "Type": cat["type"], "Name": cat["name"], "Enabled": True}
        for cat in Api(manifest).get("")["catalogs"]
        if any(cat["id"].endswith(suffix) for suffix in c["catalogs"])
    ]

    want = {**c["settings"], "Url": manifest, "MoviePath": c["moviePath"], "SeriesPath": c["seriesPath"], "Catalogs": catalogs}
    changed = sorted(k for k, v in want.items() if have.get(k) != v)
    if changed:
        api.post(path, {**have, **want})
        log(f"gelato settings: {changed}")

    # Its folders go into the libraries next to the real files, so its titles show up there. The scan
    # registers them; Gelato imports nothing into a folder Jellyfin doesn't know yet.
    folders = {f["Name"]: f for f in api.get("/Library/VirtualFolders")}
    for name, folder in ((cfg["jellyfin"]["libraries"][0]["name"], c["moviePath"]), (cfg["jellyfin"]["libraries"][1]["name"], c["seriesPath"])):
        if folder not in folders[name]["Locations"]:
            api.post("/Library/VirtualFolders/Paths?refreshLibrary=true", {"Name": name, "PathInfo": {"Path": folder}})
            log(f"library {name}: added {folder}")
            changed.append(name)

    # Gelato's catalog import has no schedule of its own: it runs every few hours, and at once when
    # its setup changed, after the scan above has registered the folders.
    tasks = {t["Key"]: t for t in api.get("/ScheduledTasks")}
    task = tasks["GelatoCatalogItemsSync"]
    triggers = [{"Type": "StartupTrigger"}, {"Type": "IntervalTrigger", "IntervalTicks": c["importHours"] * 3600 * 10**7}]
    if [{k: t.get(k) for k in x} for t, x in zip(task["Triggers"], triggers)] != triggers or len(task["Triggers"]) != len(triggers):
        api.post(f"/ScheduledTasks/{task['Id']}/Triggers", triggers)
        log(f"gelato catalog import every {c['importHours']} hours")
    if changed:
        end = time.time() + 600
        while time.time() < end and api.get(f"/ScheduledTasks/{tasks['RefreshLibrary']['Id']}")["State"] != "Idle":
            time.sleep(5)
        api.post(f"/ScheduledTasks/Running/{task['Id']}")
        log("gelato catalog import started")


# ------------------------------------------------------------------------------------ decypharr


def differs(want, have):
    """Whether have lacks anything in want. Decypharr leaves false, 0 and "" out of its config."""
    if isinstance(want, dict):
        have = have or {}
        return any(differs(v, have.get(k)) for k, v in want.items())
    if isinstance(want, list):
        have = have or []
        return len(want) != len(have) or any(differs(w, h) for w, h in zip(want, have))
    return (want or None) != (have or None)


def decypharr(k):
    c = cfg["decypharr"]
    api = Api(c["url"])
    api.wait("/version")
    for _ in range(60):  # written on first start
        if os.path.exists(c["authFile"]):
            break
        time.sleep(3)
    api.headers["Authorization"] = "Bearer " + json.load(open(c["authFile"]))["api_token"]

    want = dict(c["config"])
    want["debrids"] = [{**c["realDebrid"], "api_key": read(c["realDebridKeyFile"])}]
    # Sonarr and Radarr log in with their own URL and API key (arr_setup); Decypharr only accepts
    # arrs it knows, and uses them to clean up their queues.
    want["arrs"] = [{"name": name, "host": cfg[name]["url"], "token": k[name]} for name in ("sonarr", "radarr")]
    have = api.get("/api/config")
    changed = sorted(key for key in want if differs(want[key], have.get(key)))
    if changed:
        r = api.post("/api/config", want)
        log(f"decypharr settings: {changed}{' (restarting)' if r.get('restarted') else ''}")


# ------------------------------------------------------------------------------- sonarr/radarr


def arr_setup(name, key, jf_key):
    c = cfg[name]
    api = Api(c["url"] + "/api/v3", {"X-Api-Key": key})
    api.wait("/system/status")

    if c["rootFolder"] not in [r["path"].rstrip("/") for r in api.get("/rootfolder")]:
        api.post("/rootfolder", {"path": c["rootFolder"]})
        log(f"root folder {c['rootFolder']}")

    # Decypharr, added as qBittorrent.
    d = cfg["decypharr"]
    clients = api.get("/downloadclient")
    client = next((x for x in clients if x["implementation"] == "QBittorrent" and field(x, "port") == d["port"]), None)
    new = client is None
    if new:
        client = from_schema(api, "downloadclient", "QBittorrent")
    changed = client["name"] != "Decypharr" or not client["enable"]
    client.update(name="Decypharr", enable=True)
    # Decypharr knows the app by its URL and API key (decypharr()); the category is its name there.
    changed |= set_fields(client, {"host": "127.0.0.1", "port": d["port"], "username": c["url"], c["categoryField"]: name})
    # Read back masked, so only sent along with another change.
    if new or changed:
        set_fields(client, {"password": key})
    if not client.get("removeCompletedDownloads"):
        client["removeCompletedDownloads"] = changed = True
    if new:
        api.post("/downloadclient?forceSave=true", client)
        log("added download client Decypharr")
    elif changed:
        api.put(f"/downloadclient/{client['id']}?forceSave=true", client)
        log("download client Decypharr updated")
    # Any other qBittorrent client is rdt-client's, which Decypharr replaced; grabs sent there fail.
    for x in clients:
        if x["implementation"] == "QBittorrent" and field(x, "port") != d["port"]:
            api.call("DELETE", f"/downloadclient/{x['id']}")
            log(f"removed download client {x['name']}")

    # Nordic releases usually carry Norwegian subtitles in the file; scored in arr_profile.
    formats = api.get("/customformat")
    for cf in cfg["customFormats"]:
        if not any(f["name"] == cf["name"] for f in formats):
            api.post("/customformat", {
                "name": cf["name"],
                "includeCustomFormatWhenRenaming": False,
                "specifications": [{
                    "name": cf["name"],
                    "implementation": "ReleaseTitleSpecification",
                    "negate": False,
                    "required": True,
                    "fields": [{"name": "value", "value": cf["regex"]}],
                }],
            })
            log(f"custom format {cf['name']}")

    # Tells Jellyfin to rescan as soon as something is imported.
    if not any(n["implementation"] == "MediaBrowser" for n in api.get("/notification")):
        n = from_schema(api, "notification", "MediaBrowser")
        n["name"] = "Jellyfin"
        for k in list(n):
            if k.startswith("on") and n.get("supportsO" + k[1:]) and k not in ("onGrab", "onHealthIssue", "onHealthRestored", "onApplicationUpdate", "onManualInteractionRequired"):
                n[k] = True
        set_fields(n, {"host": "127.0.0.1", "port": cfg["jellyfin"]["port"], "apiKey": jf_key, "updateLibrary": True, "notify": False})
        api.post("/notification?forceSave=true", n)
        log("added Jellyfin connection")


def arr_profile(name, key):
    """After Recyclarr made the TRaSH profile: score the extra formats, move everything onto it."""
    c = cfg[name]
    api = Api(c["url"] + "/api/v3", {"X-Api-Key": key})
    profile = next(p for p in api.get("/qualityprofile") if p["name"] == c["profile"])
    scores = {cf["name"]: cf["score"] for cf in cfg["customFormats"]}
    changed = False
    for item in profile["formatItems"]:
        if item["name"] in scores and item["score"] != scores[item["name"]]:
            item["score"] = scores[item["name"]]
            changed = True
    if changed:
        api.put(f"/qualityprofile/{profile['id']}", profile)
        log(f"scored {list(scores)} in {profile['name']}")

    kind = "series" if name == "sonarr" else "movie"
    ids = [x["id"] for x in api.get(f"/{kind}") if x["qualityProfileId"] != profile["id"]]
    if ids:
        api.put(f"/{kind}/editor", {f"{kind}Ids": ids, "qualityProfileId": profile["id"]})
        log(f"moved {len(ids)} {kind} to {profile['name']}")
    return profile["id"]


# ------------------------------------------------------------------------------------- prowlarr


def prowlarr(k):
    c = cfg["prowlarr"]
    api = Api(c["url"] + "/api/v1", {"X-Api-Key": k["prowlarr"]})
    api.wait("/system/status")

    tags = {t["label"]: t["id"] for t in api.get("/tag")}
    if "flaresolverr" not in tags:
        tags["flaresolverr"] = api.post("/tag", {"label": "flaresolverr"})["id"]
    tag = tags["flaresolverr"]

    # Indexers tagged flaresolverr go through it (Cloudflare challenges).
    if not any(p["implementation"] == "FlareSolverr" for p in api.get("/indexerproxy")):
        p = from_schema(api, "indexerproxy", "FlareSolverr")
        p.update(name="FlareSolverr", tags=[tag])
        set_fields(p, {"host": c["flaresolverr"]})
        api.post("/indexerproxy?forceSave=true", p)
        log("added FlareSolverr proxy")

    apps = api.get("/applications")
    for app in ("sonarr", "radarr"):
        impl = app.capitalize()
        have = next((a for a in apps if a["implementation"] == impl), None)
        # An app with a tag only gets indexers with that tag; untagged, it gets them all.
        if have and have["tags"]:
            have["tags"] = []
            api.put(f"/applications/{have['id']}?forceSave=true", have)
            log(f"{impl}: cleared tags, so it gets every indexer")
        if have:
            continue
        a = from_schema(api, "applications", impl)
        a.update(name=impl, syncLevel="fullSync")
        set_fields(a, {"prowlarrUrl": c["url"], "baseUrl": cfg[app]["url"], "apiKey": k[app]})
        api.post("/applications?forceSave=true", a)
        log(f"added app {impl}")

    def named(item, name):
        return name.lower() in (item["definitionName"].lower(), item["name"].lower())

    indexers = api.get("/indexer")
    # The list is the whole set: one taken out of it goes from Prowlarr, and with it from Sonarr and Radarr.
    for i in indexers:
        if not any(named(i, name) for name in c["indexers"]):
            api.call("DELETE", f"/indexer/{i['id']}")
            log(f"removed indexer {i['name']}")
    schema = None
    errors = []
    for want_name, opts in c["indexers"].items():
        want_tags = [tag] if opts["flaresolverr"] else []
        priority = opts.get("priority", 25)  # Prowlarr's default
        have = next((i for i in indexers if named(i, want_name)), None)
        if have:
            tags = [t for t in have["tags"] if t != tag] + want_tags
            if sorted(tags) != sorted(have["tags"]) or have["priority"] != priority:
                have.update(tags=tags, priority=priority)
                api.put(f"/indexer/{have['id']}?forceSave=true", have)
                log(f"indexer {have['name']}: flaresolverr {opts['flaresolverr']}, priority {priority}")
            continue
        schema = schema or api.get("/indexer/schema")
        s = next((s for s in schema if named(s, want_name)), None)
        if s is None:
            log(f"indexer {want_name}: not in Prowlarr's list, skipped")
            continue
        s.update(enable=True, appProfileId=1, tags=want_tags, priority=priority)
        try:
            # Prowlarr tests the site first; one that is down must not block the rest.
            api.post("/indexer?forceSave=true", s)
            log(f"added indexer {s['name']}")
        except RuntimeError as e:
            errors.append(f"{want_name}: {str(e)[:200]}")
    if errors:
        raise RuntimeError("; ".join(errors))


# --------------------------------------------------------------------------------------- bazarr


def bazarr(k):
    c = cfg["bazarr"]
    api = Api(c["url"] + "/api", {"X-API-KEY": k["bazarr"]})
    api.wait("/system/status")

    want = {
        "settings-general-use_sonarr": True,
        "settings-general-use_radarr": True,
        "settings-sonarr-ip": "127.0.0.1",
        "settings-sonarr-port": cfg["sonarr"]["port"],
        "settings-sonarr-apikey": k["sonarr"],
        "settings-radarr-ip": "127.0.0.1",
        "settings-radarr-port": cfg["radarr"]["port"],
        "settings-radarr-apikey": k["radarr"],
        "settings-general-enabled_providers": c["providers"],
        "settings-general-serie_default_enabled": True,
        "settings-general-serie_default_profile": 1,
        "settings-general-movie_default_enabled": True,
        "settings-general-movie_default_profile": 1,
        # Sync every subtitle to the audio (ffsubsync), whatever the provider's score.
        "settings-subsync-use_subsync": True,
        "settings-subsync-use_subsync_threshold": False,
        "settings-subsync-use_subsync_movie_threshold": False,
    }
    for key, path in c["secretFiles"].items():
        want[key] = read(path)
    current = api.get("/system/settings")
    form = {}
    for key, value in want.items():
        _, section, option = key.split("-", 2)
        have = current.get(section, {}).get(option)
        if isinstance(value, list):
            if sorted(have or []) != sorted(value):
                form[key] = value
        elif str(have) != str(value):
            form[key] = str(value).lower() if isinstance(value, bool) else str(value)

    # One profile, id 1, used as the default for new series and movies.
    profile = {
        "profileId": 1,
        "name": c["profileName"],
        "cutoff": None,
        "items": [
            {"id": i + 1, "language": lang, "audio_exclude": "False", "audio_only_include": "False", "hi": "False", "forced": "False"}
            for i, lang in enumerate(c["languages"])
        ],
        "mustContain": [],
        "mustNotContain": [],
        "originalFormat": False,
    }
    enabled = sorted(lang["code2"] for lang in api.get("/system/languages") if lang["enabled"])
    profiles = api.get("/system/languages/profiles")
    have = next((p for p in profiles if p["profileId"] == 1), None)
    if enabled != sorted(c["languages"]) or not have or have["name"] != profile["name"] or [i["language"] for i in have["items"]] != c["languages"]:
        form["languages-enabled"] = c["languages"]
        form["languages-profiles"] = json.dumps([profile] + [p for p in profiles if p["profileId"] != 1])
    if form:
        api.post("/system/settings", form=form)
        log(f"bazarr settings: {sorted(k for k in form if 'apikey' not in k and 'password' not in k)}")


# ---------------------------------------------------------------------------------------- seerr


# Seerr's permission bits (server/lib/permissions.ts).
PERM_ADMIN = 2
PERM_REQUEST = 32
PERM_AUTO_APPROVE = 128


def seerr(k, profiles):
    c = cfg["seerr"]
    settings_file = os.path.join(c["configDir"], "settings.json")
    api = Api(c["url"] + "/api/v1", cookies=True)
    api.wait("/status")
    for _ in range(60):  # written on first start
        if os.path.exists(settings_file):
            break
        time.sleep(3)
    settings = json.load(open(settings_file))

    if not settings["jellyfin"].get("ip"):
        # The first Jellyfin login becomes Seerr's owner and connects the server.
        jf = cfg["jellyfin"]
        admin = jf["users"][0]
        api.post("/auth/jellyfin", {
            "username": admin["name"],
            "password": read(admin["passwordFile"]),
            "hostname": "127.0.0.1",
            "port": jf["port"],
            "urlBase": "",
            "useSsl": False,
            "serverType": 2,
            "email": f"{admin['name']}@{c['emailDomain']}",
        })
        log("connected Seerr to Jellyfin")

    api.headers["X-Api-Key"] = settings["main"]["apiKey"]
    # Where "Play on Jellyfin" links point; Seerr itself talks to Jellyfin on localhost.
    if settings["jellyfin"].get("externalHostname") != c["jellyfinUrl"]:
        api.post("/settings/jellyfin", {"externalHostname": c["jellyfinUrl"]})
        log(f"Seerr links to Jellyfin at {c['jellyfinUrl']}")
    if c["autoApprove"]:
        # New users get it from the defaults; users already imported from Jellyfin get it here.
        auto = PERM_REQUEST | PERM_AUTO_APPROVE
        main_settings = api.get("/settings/main")
        if main_settings["defaultPermissions"] & auto != auto:
            api.post("/settings/main", {"defaultPermissions": main_settings["defaultPermissions"] | auto})
            log("Seerr approves requests automatically")
        for user in api.get("/user?take=1000")["results"]:
            if user["permissions"] & PERM_ADMIN == 0 and user["permissions"] & auto != auto:
                api.post(f"/user/{user['id']}/settings/permissions", {"permissions": user["permissions"] | auto})
                log(f"Seerr: {user['displayName']} auto-approved")
    if not settings["public"]["initialized"]:
        for lib in api.post("/settings/jellyfin/library/sync"):
            if not lib["enabled"]:
                api.put(f"/settings/jellyfin/library/{lib['id']}", {"enabled": True})

    for name in ("radarr", "sonarr"):
        a = cfg[name]
        want = {
            "name": name.capitalize(),
            "hostname": "127.0.0.1",
            "port": a["port"],
            "apiKey": k[name],
            "useSsl": False,
            "baseUrl": "",
            "activeProfileId": profiles[name],
            "activeProfileName": a["profile"],
            "activeDirectory": a["rootFolder"],
            "is4k": False,
            "isDefault": True,
            "syncEnabled": True,
            "preventSearch": False,
            "tags": [],
        }
        if name == "radarr":
            want["minimumAvailability"] = "released"
        else:
            want.update(
                activeAnimeProfileId=profiles[name],
                activeAnimeProfileName=a["profile"],
                activeAnimeDirectory=a["rootFolder"],
                seriesType="standard",
                animeSeriesType="anime",
                enableSeasonFolders=True,
            )
        servers = api.get(f"/settings/{name}")
        have = next((s for s in servers if s["port"] == a["port"] and not s["is4k"]), None)
        if have is None:
            api.post(f"/settings/{name}", want)
            log(f"added {name} to Seerr")
        elif any(have.get(f) != v for f, v in want.items() if f != "name"):
            body = {**have, **{f: v for f, v in want.items() if f != "name"}}
            del body["id"]  # read-only in Seerr's API
            api.put(f"/settings/{name}/{have['id']}", body)
            log(f"updated {name} in Seerr")

    if not settings["public"]["initialized"]:
        api.post("/settings/initialize")
        log("finished Seerr setup")


# ----------------------------------------------------------------------------------------- main


def main():
    k = keys()
    jf_key = step("jellyfin", jellyfin, cfg["jellyfin"])
    step("decypharr", decypharr, k)
    manifest = step("aiostreams", aiostreams, cfg["aiostreams"])
    if jf_key and manifest:
        step("gelato", gelato, cfg["gelato"], jf_key, manifest)
    else:
        failed.append("gelato (waits for Jellyfin and AIOStreams)")
    for name in ("sonarr", "radarr"):
        step(f"{name}: clients and folders", arr_setup, name, k[name], jf_key)
    # TRaSH quality profiles and custom formats (recyclarr.nix); the profiles must exist below.
    step("recyclarr", systemctl, "start", "recyclarr.service")
    profiles = {name: step(f"{name}: profile", arr_profile, name, k[name]) for name in ("sonarr", "radarr")}
    step("prowlarr", prowlarr, k)
    step("bazarr", bazarr, k)
    if all(profiles.values()):
        step("seerr", seerr, k, profiles)
    else:
        failed.append("seerr (waits for the profiles)")
    if failed:
        log(f"failed: {', '.join(failed)}; retrying later")
        sys.exit(1)
    log("all converged")


if __name__ == "__main__":
    main()
