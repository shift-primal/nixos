_:

{

    flake.modules.nixos.homelab =
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
