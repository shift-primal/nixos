_:

{
    # Seerr (formerly Jellyseerr): a browsable catalog where a click on "Request" sends a show to
    # Sonarr or a movie to Radarr (arr.nix). Logs in with Jellyfin accounts. Tailscale only.
    flake.modules.nixos.media =
        { config, ... }:
        let
            cfg = config.services.seerr;
        in
        {
            services.seerr.enable = true;
            networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.port ];

            # Settings, users and request history. It runs as a DynamicUser, so its state is under
            # /var/lib/private. Spelled out: reading it from systemd.services loops, because the
            # backup's own unit is built from these paths.
            homelab.backup.paths = [ "/var/lib/private/seerr" ];
        };
}
