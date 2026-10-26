_:

{
    # Reverse proxy for every web service on the host. Each feature adds its own
    # services.caddy.virtualHosts entry (komodo/core.nix), named "http://<host>": Cloudflare
    # terminates TLS and the tunnel (cloudflared.nix) is the only client, so Caddy serves plain
    # HTTP on localhost and never asks for certificates.
    flake.modules.nixos.caddy.services.caddy = {
        enable = true;
        globalConfig = ''
            auto_https off
            default_bind 127.0.0.1 [::1]
        '';
    };
}
