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

                # The tunnel runs over QUIC, which wants ~7 MB UDP socket buffers; the kernel's 208 KB
                # default caps its throughput, uploads to OpenCloud included (cloudflared then logs
                # "failed to sufficiently increase receive buffer size").
                boot.kernel.sysctl = {
                    "net.core.rmem_max" = 7500000;
                    "net.core.wmem_max" = 7500000;
                };
            };
        };
}
