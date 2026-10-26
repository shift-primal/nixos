{
    writeShellApplication,
    cloudflared,
    curl,
    jq,
}:

# Moves hostnames onto the homelab's Cloudflare Tunnel (modules/server/cloudflared.nix).
# `cloudflared tunnel route dns --overwrite-dns` only replaces CNAMEs, so the old A/AAAA records
# (and CNAMEs to elsewhere, e.g. Railway) are deleted first, with the API token cloudflared's
# login stored in ~/.cloudflared/cert.pem.
writeShellApplication {
    name = "cutover";
    runtimeInputs = [
        cloudflared
        curl
        jq
    ];
    text = ''
        if [ $# -eq 0 ]; then
            echo "usage: cutover <hostname>..." >&2
            exit 1
        fi
        creds=$(sed -n '/BEGIN ARGO TUNNEL TOKEN/,/END/p' "$HOME/.cloudflared/cert.pem" | grep -v -- ----- | base64 -d)
        zone=$(jq -r .zoneID <<<"$creds")
        token=$(jq -r .apiToken <<<"$creds")
        api="https://api.cloudflare.com/client/v4/zones/$zone/dns_records"
        for host in "$@"; do
            for id in $(curl -fsS -H "Authorization: Bearer $token" "$api?name=$host" | jq -r '.result[]
                | select(.type == "A" or .type == "AAAA" or (.type == "CNAME" and (.content | endswith("cfargotunnel.com") | not)))
                | .id'); do
                curl -fsS -X DELETE -H "Authorization: Bearer $token" "$api/$id" >/dev/null
            done
            cloudflared tunnel route dns homelab "$host"
        done
    '';
}
