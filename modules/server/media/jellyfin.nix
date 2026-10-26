_:

{
    # Jellyfin, reachable over Tailscale only: streaming video through the Cloudflare tunnel breaks
    # Cloudflare's terms, so it gets no Caddy vhost. Open http://<hostname>:8096 from the tailnet.
    # The GPU side (VA-API, codecs) is per machine: modules/hosts/kash-homelab/intel.nix.
    flake.modules.nixos.media =
        { config, ... }:
        {
            services.jellyfin.enable = true;
            users.users.jellyfin.extraGroups = [ "media" ];

            # Jellyfin listens on every interface; the firewall lets only the tailnet in.
            networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8096 ];

            # The media disk is mounted nofail. Without it a library scan would find empty folders
            # and drop every item, so Jellyfin waits for the mount instead.
            systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ config.homelab.media.root ];

            # Config, users, watch history and fetched metadata. The media itself is not copied
            # off-site (backup.nix); the cache dir is outside this path.
            homelab.backup.paths = [ config.services.jellyfin.dataDir ];
        };
}
