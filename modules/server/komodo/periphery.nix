_:

{
    # The Komodo agent that runs stacks on this host. Native from nixpkgs; Core is in core.nix.
    flake.modules.nixos.komodo =
        { config, ... }:
        {
            services.komodo-periphery = {
                enable = true;
                # Outbound mode: Periphery dials Core, so it opens no port of its own.
                outbound = {
                    coreAddress = "ws://127.0.0.1:9120";
                    # Core creates this server on first start (KOMODO_FIRST_SERVER_NAME in core.nix).
                    connectAs = config.networking.hostName;
                };
                # Core writes its key pair to its keys volume on first start.
                auth.corePublicKeys = [ "file:/var/lib/komodo-core/keys/core.pub" ];
            };

            systemd.services.komodo-periphery = {
                after = [ "docker-komodo-core.service" ];
                wants = [ "docker-komodo-core.service" ];
            };
        };
}
