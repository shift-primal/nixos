_:

{
    # Public way in. The tunnel dials out to Cloudflare, so no port is open on the router or the
    # firewall. Every hostname routed to it lands on Caddy (caddy.nix), which picks the site.
    flake.modules.nixos.cloudflared =
        { config, lib, ... }:
        let
            inherit (config.homelab.tunnel) id;
        in
        {
            options.homelab.tunnel.id = lib.mkOption {
                type = lib.types.str;
                description = "UUID printed by `cloudflared tunnel create`. Not a secret; the credentials are.";
            };

            config = {
                # The JSON `cloudflared tunnel create` writes to ~/.cloudflared/<id>.json.
                sops.secrets."cloudflared/credentials".restartUnits = [ "cloudflared-tunnel-${id}.service" ];

                services.cloudflared = {
                    enable = true;
                    tunnels.${id} = {
                        credentialsFile = config.sops.secrets."cloudflared/credentials".path;
                        default = "http://localhost:80";
                    };
                };
            };
        };
}
