_:

{
    # Reverse proxy for every web service on the host. Each feature adds its own
    # services.caddy.virtualHosts entry (komodo/core.nix), named "http://<host>": Cloudflare
    # terminates TLS and the tunnel (cloudflared.nix) is the only client, so Caddy serves plain
    # HTTP on localhost and never asks for certificates.
    flake.modules.nixos.homelab.services.caddy = {
        enable = true;
        # Requests from cloudflared (localhost) carry the visitor's address in Cf-Connecting-Ip; trusting
        # it lets apps behind Caddy (pocket-id.nix) rate-limit and log the visitor, not 127.0.0.1.
        globalConfig = ''
            auto_https off
            default_bind 127.0.0.1 [::1]
            servers {
                trusted_proxies static 127.0.0.1/32 ::1/128
                client_ip_headers Cf-Connecting-Ip X-Forwarded-For
            }
        '';
    };
}
