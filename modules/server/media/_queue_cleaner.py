"""Fails downloads that rdt-client gave up on, so Sonarr and Radarr pick another release.

rdt-client reports a torrent Real-Debrid refused (e.g. "Infringing file") as qBittorrent's
"error" state, and one without seeders as "stalledDL". Sonarr and Radarr show both only as a
warning and wait forever. This removes such items from the queue once they have been stuck long
enough, blocklists the release and lets the app search again. Run by media-queue-cleaner.timer
(queue-cleaner.nix) with a JSON config as its only argument.
"""

import json
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime

cfg = json.load(open(sys.argv[1]))
failed = False

for name, app in cfg["apps"].items():
    try:
        key = ET.parse(app["configFile"]).getroot().findtext("ApiKey")
        headers = {"X-Api-Key": key}

        def call(method, path):
            req = urllib.request.Request(app["url"] + "/api/v3" + path, headers=headers, method=method)
            with urllib.request.urlopen(req, timeout=60) as r:
                text = r.read().decode()
            return json.loads(text) if text else None

        records = call("GET", "/queue?pageSize=1000")["records"]
        for rec in records:
            # Still "downloading" as far as the app knows, but the client reports a problem.
            # rdt-client is the only torrent client.
            if rec.get("protocol") != "torrent" or rec.get("status") != "warning":
                continue
            if rec.get("trackedDownloadState") != "downloading":
                continue
            added = datetime.fromisoformat(rec.get("added") or "1970-01-01T00:00:00Z").timestamp()
            if time.time() - added < cfg["minutes"] * 60:
                continue
            query = urllib.parse.urlencode({"removeFromClient": "true", "blocklist": "true", "skipRedownload": "false"})
            call("DELETE", f"/queue/{rec['id']}?{query}")
            print(f"{name}: failed {rec.get('title')} ({rec.get('errorMessage')}), searching again", flush=True)
    except Exception as e:  # noqa: BLE001  one app down must not stop the other
        print(f"{name}: {e}", flush=True)
        failed = True

sys.exit(1 if failed else 0)
