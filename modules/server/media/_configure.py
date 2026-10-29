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
        {**known.get((cat["id"], cat["type"]), {}), "Id": cat["id"], "Type": cat["type"], "Name": cat["name"], "Enabled": True, "MaxItems": size}
        for cat in Api(manifest).get("")["catalogs"]
        for suffix, size in c["catalogs"].items()
        if cat["id"].endswith(suffix)
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


# ----------------------------------------------------------------------------------------- main


def main():
    jf_key = step("jellyfin", jellyfin, cfg["jellyfin"])
    manifest = step("aiostreams", aiostreams, cfg["aiostreams"])
    if jf_key and manifest:
        step("gelato", gelato, cfg["gelato"], jf_key, manifest)
    else:
        failed.append("gelato (waits for Jellyfin and AIOStreams)")
    if failed:
        log(f"failed: {', '.join(failed)}; retrying later")
        sys.exit(1)
    log("all converged")


if __name__ == "__main__":
    main()
