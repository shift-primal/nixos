"""Converges the media stack to the settings in configure.nix, through each app's own API.

Run as root by media-configure.service with a JSON config as its only argument. Every step reads
the current state first and only writes what differs, so it is safe to run again at any time. It
creates and fixes what the config names and never deletes anything else.
"""

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
        api.post(f"/Library/VirtualFolders?{q}", {"LibraryOptions": {"EnableRealtimeMonitor": True, "PathInfos": [{"Path": lib["path"]}]}})
        log(f"added library {lib['name']} at {lib['path']}")

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


# ----------------------------------------------------------------------------------- rdt-client


def rdtclient(c):
    api = Api(c["url"], cookies=True)
    password = read(c["passwordFile"])
    api.wait("/Api/Authentication/IsLoggedIn")
    login = {"userName": c["user"], "password": password}
    try:
        api.post("/Api/Authentication/Login", login)
    except RuntimeError:
        # Create only succeeds while there is no user yet; otherwise the password is wrong.
        api.post("/Api/Authentication/Create", login)
        log(f"created rdt-client user {c['user']}")

    want = dict(c["settings"])
    want["Provider:ApiKey"] = read(c["realDebridKeyFile"])
    current = {s["key"]: s.get("value") for s in api.get("/Api/Settings")}
    changes = [{"key": k, "value": v} for k, v in want.items() if str(current.get(k)) != str(v)]
    if changes:
        api.put("/Api/Settings", changes)
        log(f"rdt-client settings: {[x['key'] for x in changes]}")


# ------------------------------------------------------------------------------- sonarr/radarr


def arr_setup(name, key, jf_key):
    c = cfg[name]
    api = Api(c["url"] + "/api/v3", {"X-Api-Key": key})
    api.wait("/system/status")

    if c["rootFolder"] not in [r["path"].rstrip("/") for r in api.get("/rootfolder")]:
        api.post("/rootfolder", {"path": c["rootFolder"]})
        log(f"root folder {c['rootFolder']}")

    # rdt-client, added as qBittorrent.
    rdt = cfg["rdtclient"]
    clients = api.get("/downloadclient")
    client = next((d for d in clients if d["implementation"] == "QBittorrent" and field(d, "port") == rdt["port"]), None)
    new = client is None
    if new:
        client = from_schema(api, "downloadclient", "QBittorrent")
        client.update(name="rdt-client", enable=True)
        set_fields(client, {c["categoryField"]: name})
    changed = set_fields(client, {"host": "127.0.0.1", "port": rdt["port"], "username": rdt["user"], "password": read(rdt["passwordFile"])})
    if not client.get("removeCompletedDownloads"):
        client["removeCompletedDownloads"] = changed = True
    if new:
        api.post("/downloadclient?forceSave=true", client)
        log("added download client rdt-client")
    elif changed:
        api.put(f"/downloadclient/{client['id']}?forceSave=true", client)

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

    indexers = api.get("/indexer")
    schema = None
    errors = []
    for want_name, opts in c["indexers"].items():
        want_tags = [tag] if opts["flaresolverr"] else []
        have = next((i for i in indexers if want_name.lower() in (i["definitionName"].lower(), i["name"].lower())), None)
        if have:
            if want_tags and tag not in have["tags"]:
                have["tags"].append(tag)
                api.put(f"/indexer/{have['id']}?forceSave=true", have)
                log(f"tagged {have['name']} flaresolverr")
            continue
        schema = schema or api.get("/indexer/schema")
        s = next((s for s in schema if want_name.lower() in (s["definitionName"].lower(), s["name"].lower())), None)
        if s is None:
            log(f"indexer {want_name}: not in Prowlarr's list, skipped")
            continue
        s.update(enable=True, appProfileId=1, tags=want_tags)
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
    step("rdt-client", rdtclient, cfg["rdtclient"])
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
