_:

{
    # Sonarr (shows), Radarr (movies) and Prowlarr (indexers, synced into both). Tailscale only, like
    # Jellyfin. The download client they talk to is qBittorrent at 127.0.0.1:8081 (qbittorrent.nix).
    # Prowlarr reaches the indexers directly, not through the VPN: it only searches.
    flake.modules.nixos.media =
        { config, lib, ... }:
        let
            inherit (config.homelab.media) root;
            arr = [
                "sonarr"
                "radarr"
            ];
        in
        {
            services =
                lib.genAttrs arr (_: {
                    enable = true;
                    # Writes into the libraries and hardlinks from downloads/ (library.nix).
                    group = "media";
                })
                // {
                    prowlarr.enable = true;
                };

            # Without the disk an import would fail or land on the root filesystem.
            systemd.services = lib.genAttrs arr (_: {
                unitConfig.RequiresMountsFor = [ root ];
                # Group-writable files, like the folders they land in.
                serviceConfig.UMask = lib.mkForce "0002";
            });

            networking.firewall.interfaces.tailscale0.allowedTCPPorts = map (
                name: config.services.${name}.settings.server.port
            ) (arr ++ [ "prowlarr" ]);

            # Series, movies, history, indexers and API keys. Prowlarr runs as a DynamicUser, so its
            # state is under /var/lib/private.
            homelab.backup.paths = [
                config.services.sonarr.dataDir
                config.services.radarr.dataDir
                "/var/lib/private/prowlarr"
            ];
        };
}
