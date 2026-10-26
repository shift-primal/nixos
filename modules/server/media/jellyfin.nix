_:

{
    # Jellyfin, reachable from the home LAN and the tailnet but not the internet: streaming video
    # through the Cloudflare tunnel breaks Cloudflare's terms, so it gets no Caddy vhost. Open
    # http://<hostname>:8096.
    # The GPU side (VA-API, codecs) is per machine: modules/hosts/kash-homelab/intel.nix.
    flake.modules.nixos.media =
        { config, ... }:
        {
            services.jellyfin.enable = true;
            users.users.jellyfin.extraGroups = [ "media" ];

            # Open on every interface, so the TVs at home need no Tailscale. The router forwards no
            # ports, so that means the LAN and the tailnet. UDP 7359 lets apps on the LAN find it.
            networking.firewall = {
                allowedTCPPorts = [ 8096 ];
                allowedUDPPorts = [ 7359 ];
            };

            # The media disk is mounted nofail. Without it a library scan would find empty folders
            # and drop every item, so Jellyfin waits for the mount instead.
            systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ config.homelab.media.root ];

            # Config, users, watch history and fetched metadata. The media itself is not copied
            # off-site (backup.nix); the cache dir is outside this path.
            homelab.backup.paths = [ config.services.jellyfin.dataDir ];
        };
}
