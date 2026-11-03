_:

{

    flake.modules.nixos.homelab =
        { config, ... }:
        {
            services.komodo-periphery = {
                enable = true;

                outbound = {
                    coreAddress = "ws://127.0.0.1:9120";

                    connectAs = config.networking.hostName;
                };

                auth.corePublicKeys = [ "file:/var/lib/komodo-core/keys/core.pub" ];
            };

            systemd.services.komodo-periphery = {
                after = [ "docker-komodo-core.service" ];
                wants = [ "docker-komodo-core.service" ];
            };
        };
}
