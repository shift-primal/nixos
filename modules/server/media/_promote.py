"""Turns Gelato titles someone played into real ones (gelato-promote.nix).

A played Gelato movie, or an episode of a Gelato season, is requested in Seerr, which sends it to
Radarr or Sonarr; Bazarr then gives the real copy synced subtitles. Once the real copy is in the
library, the Gelato title beside it goes. Every run picks up where the last one stopped.
"""

import json
import os
import sqlite3
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone

cfg = json.load(open(sys.argv[1]))


def log(msg):
    print(msg, flush=True)


def call(base, headers, method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method, headers={**headers, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            text = r.read().decode()
            return r.status, json.loads(text) if text else None
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")


def jellyfin(method, path, body=None):
    status, data = call(cfg["jellyfin"]["url"], jf_headers, method, path, body)
    if status >= 300:
        raise RuntimeError(f"Jellyfin {method} {path}: HTTP {status}: {str(data)[:300]}")
    return data


def items(**query):
    query = {"Recursive": "true", "Fields": "ProviderIds", "userId": admin, **query}
    return jellyfin("GET", "/Items?" + urllib.parse.urlencode(query))["Items"]


def tmdb_id(item):
    """Gelato's own ids are Stremio ones (usually IMDb); Jellyfin's TMDB lookup maps those."""
    ids = item.get("ProviderIds") or {}
    if ids.get("Tmdb"):
        return int(ids["Tmdb"])
    if not ids.get("Imdb"):
        return None
    kind = "Movie" if item["Type"] == "Movie" else "Series"
    try:
        found = jellyfin("POST", f"/Items/RemoteSearch/{kind}", {"SearchInfo": {"ProviderIds": {"Imdb": ids["Imdb"]}}, "SearchProviderName": "TheMovieDb"})
    except RuntimeError as e:
        log(f"TMDB lookup of {ids['Imdb']} failed: {e}")
        return None
    tmdb = next((r["ProviderIds"]["Tmdb"] for r in found if (r.get("ProviderIds") or {}).get("Tmdb")), None)
    return int(tmdb) if tmdb else None


def request(item):
    """The Seerr request for a played item, or None when it isn't Gelato's."""
    if "Stremio" not in (item.get("ProviderIds") or {}):
        return None
    if item["Type"] == "Movie":
        tmdb = tmdb_id(item)
        return {"mediaType": "movie", "mediaId": tmdb} if tmdb else None
    if item["Type"] == "Episode" and item.get("SeriesId") and item.get("ParentIndexNumber"):
        series = items(ids=item["SeriesId"])
        tmdb = tmdb_id(series[0]) if series else None
        return {"mediaType": "tv", "mediaId": tmdb, "seasons": [item["ParentIndexNumber"]]} if tmdb else None
    return None


def promote(state):
    """Requests what was played since the last run."""
    since = state.get("since") or (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
    entries = jellyfin("GET", "/System/ActivityLog/Entries?" + urllib.parse.urlencode({"minDate": since, "hasUserId": "true"}))["Items"]
    dates = {e["Id"]: e["Date"] for e in entries}
    done = set(state.get("done", []))
    for e in sorted(entries, key=lambda e: e["Date"]):
        if e["Type"] != "VideoPlayback" or not e.get("ItemId") or e["Id"] in done:
            continue
        found = items(ids=e["ItemId"])
        body = request(found[0]) if found else None
        if body is None and found and "Stremio" in (found[0].get("ProviderIds") or {}):
            log(f"no TMDB id for {found[0]['Name']}, not requested")
        if body:
            status, answer = call(cfg["seerr"]["url"] + "/api/v1", seerr_headers, "POST", "/request", body)
            if status < 300:
                log(f"requested {found[0]['Name']}: {body}")
            elif status != 409 and "already" not in str(answer).lower():
                # Seerr not answering at all raises instead, so the next run tries this entry again.
                log(f"Seerr refused {found[0]['Name']} {body}: HTTP {status}: {str(answer)[:300]}")
        done.add(e["Id"])
        # Entries on the last date come back next run; only those need remembering.
        state["since"] = e["Date"]
        state["done"] = [i for i in done if dates.get(i) == e["Date"]]


def deduplicate():
    """Deletes Gelato movies and series that now have a real copy. Through Gelato's own delete
    (it needs a user), which keeps its stream rows from coming back."""
    for kind in ("Movie", "Series"):
        real, gelato = set(), []
        for item in items(IncludeItemTypes=kind):
            ids = item.get("ProviderIds") or {}
            keys = {(k, ids[k]) for k in ("Tmdb", "Imdb", "Tvdb") if ids.get(k)}
            if "Stremio" in ids:
                gelato.append((item, keys))
            else:
                real |= keys
        for item, keys in gelato:
            if keys & real:
                jellyfin("DELETE", f"/Items/{item['Id']}?userId={admin}")
                log(f"deleted the Gelato copy of {item['Name']}")


with sqlite3.connect(f"file:{cfg['jellyfin']['db']}?mode=ro", uri=True) as con:
    row = con.execute("SELECT AccessToken FROM ApiKeys WHERE Name = 'media-configure'").fetchone()
if not row:
    sys.exit("no Jellyfin API key yet; media-configure makes it")
jf_headers = {"Authorization": f'MediaBrowser Token="{row[0]}"'}
admin = next(u["Id"] for u in jellyfin("GET", "/Users") if u["Policy"]["IsAdministrator"])
with open(os.path.join(cfg["seerr"]["configDir"], "settings.json")) as f:
    seerr_headers = {"X-Api-Key": json.load(f)["main"]["apiKey"]}

state_file = cfg["stateFile"]
state = json.load(open(state_file)) if os.path.exists(state_file) else {}
try:
    promote(state)
finally:
    with open(state_file, "w") as f:
        json.dump(state, f)
deduplicate()
