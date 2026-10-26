_:

{
    # Sonarr (shows), Radarr (movies) and Prowlarr (indexers, synced into both). Tailscale only, like
    # Jellyfin. Their download client is Decypharr (decypharr.nix), added as qBittorrent, whose API
    # it speaks. configure.nix links them all up; recyclarr.nix sets the quality profiles.
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
                    # Moves Decypharr's symlinks from downloads/ into the libraries (library.nix).
                    group = "media";
                })
                // {
                    prowlarr.enable = true;
                    # Solves Cloudflare challenges for indexers behind it. media-configure
                    # (configure.nix) adds it to Prowlarr as a proxy for indexers tagged flaresolverr.
                    flaresolverr.enable = true;
                };

            # Without the disk an import would fail or land on the root filesystem.
            systemd.services =
                lib.genAttrs arr (_: {
                    unitConfig.RequiresMountsFor = [ root ];
                    # Group-writable files, like the folders they land in.
                    serviceConfig.UMask = lib.mkForce "0002";
                })
                // {
                    # Only Prowlarr on this host needs it.
                    flaresolverr.environment.HOST = "127.0.0.1";
                };

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
