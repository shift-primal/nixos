"""Converges Pocket ID's users, groups and OIDC clients to homelab.pocketId (pocket-id.nix).

Run as root by pocket-id-provision.service with a JSON config as its only argument. It talks to
Pocket ID's admin API with the static API key, reads the current state first and only writes what
differs. It creates and fixes what the config names and never deletes: a user or client added in
the web UI stays. Fields the config doesn't set (a user's email, a client's logo) are left as they are.
"""

import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

cfg = json.load(open(sys.argv[1]))


def log(msg):
    print(msg, flush=True)


def read(path):
    with open(path) as f:
        return f.read().strip()


headers = {"X-API-Key": read(cfg["apiKeyFile"]), "Content-Type": "application/json"}


def call(method, path, body=None, ok=(200, 201, 204)):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(cfg["url"] + "/api" + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            status, text = r.status, r.read().decode()
    except urllib.error.HTTPError as e:
        status, text = e.code, e.read().decode(errors="replace")
    if status not in ok:
        raise RuntimeError(f"{method} {path}: HTTP {status}: {text[:300]}")
    return json.loads(text) if text else None


def listing(path):
    sep = "&" if "?" in path else "?"
    return call("GET", f"{path}{sep}pagination[limit]=1000")["data"]


def differs(cur, want):
    """Pocket ID returns an empty optional field as null."""
    return any(cur.get(k) != v and not (cur.get(k) is None and v in ("", [])) for k, v in want.items())


def wait():
    end = time.time() + 300
    while True:
        try:
            return call("GET", "/users/me")
        except (OSError, RuntimeError) as e:
            if time.time() > end:
                raise RuntimeError(f"Pocket ID did not come up: {e}")
            time.sleep(3)


def users():
    existing = {u["username"]: u for u in listing("/users")}
    ids = {}
    for name, u in cfg["users"].items():
        first, _, last = u["fullName"].partition(" ")
        want = {
            "username": name,
            "firstName": first,
            "lastName": last,
            "displayName": u["fullName"],
            "isAdmin": u["admin"],
        }
        cur = existing.get(name)
        if cur is None:
            cur = call("POST", "/users", want)
            log(f"created user {name}")
        elif differs(cur, want):
            keep = {k: cur.get(k) for k in ("email", "emailVerified", "locale", "disabled")}
            call("PUT", f"/users/{cur['id']}", {**keep, **want})
            log(f"updated user {name}")
        ids[name] = cur["id"]
    return ids


def groups(user_ids):
    existing = {g["name"]: g for g in listing("/user-groups")}
    ids = {}
    for name, g in cfg["groups"].items():
        cur = existing.get(name)
        if cur is None:
            cur = call("POST", "/user-groups", {"name": name, "friendlyName": g["friendlyName"]})
            log(f"created group {name}")
        elif cur["friendlyName"] != g["friendlyName"]:
            call("PUT", f"/user-groups/{cur['id']}", {"name": name, "friendlyName": g["friendlyName"]})
        ids[name] = cur["id"]
        full = call("GET", f"/user-groups/{cur['id']}")

        claims = sorted(({"key": k, "value": v} for k, v in g["claims"].items()), key=lambda c: c["key"])
        if sorted(full.get("customClaims") or [], key=lambda c: c["key"]) != claims:
            call("PUT", f"/custom-claims/user-group/{cur['id']}", claims)
            log(f"{name}: claims {g['claims']}")

        # Members are the whole set: someone taken off the list leaves the group.
        members = sorted(user_ids[m] for m in g["members"])
        if sorted(u["id"] for u in full.get("users") or []) != members:
            call("PUT", f"/user-groups/{cur['id']}/users", {"userIds": members})
            log(f"{name}: members {g['members']}")
    return ids


def clients(group_ids):
    for cid, c in cfg["clients"].items():
        want = {
            "name": c["name"],
            "callbackURLs": c["callbackURLs"],
            "logoutCallbackURLs": c["logoutCallbackURLs"],
            "isPublic": True,
            "pkceEnabled": True,
            "launchURL": c["launchURL"],
            "isGroupRestricted": bool(c["groups"]),
        }
        cur = call("GET", f"/oidc/clients/{urllib.parse.quote(cid)}", ok=(200, 404))
        if cur is None or "id" not in cur:
            cur = call("POST", "/oidc/clients", {"id": cid, **want})
            log(f"created client {cid}")
        elif differs(cur, want):
            # The update replaces the whole client, so the fields not set here are sent back as they are.
            keep = {k: cur.get(k) for k in ("description", "requiresReauthentication", "requiresPushedAuthorizationRequests", "skipConsent", "credentials", "hasLogo", "hasDarkLogo", "backchannelLogoutURL", "accessTokenDurationMinutes", "refreshTokenDurationMinutes")}
            call("PUT", f"/oidc/clients/{urllib.parse.quote(cid)}", {**keep, **want})
            log(f"updated client {cid}")

        allowed = sorted(group_ids[g] for g in c["groups"])
        if sorted(g["id"] for g in cur.get("allowedUserGroups") or []) != allowed:
            call("PUT", f"/oidc/clients/{urllib.parse.quote(cid)}/allowed-user-groups", {"userGroupIds": allowed})
            log(f"{cid}: allowed groups {c['groups']}")


wait()
clients(groups(users()))
log("Pocket ID converged")
