_:

{
    # Bazarr: fetches subtitles for everything Sonarr and Radarr import (arr.nix) and saves them
    # next to the video, where Jellyfin picks them up. Tailscale only, like the arrs.
    flake.modules.nixos.media =
        { config, lib, ... }:
        let
            cfg = config.services.bazarr;
        in
        {
            services.bazarr = {
                enable = true;
                # Writes .srt files into the libraries (library.nix).
                group = "media";
            };

            systemd.services.bazarr = {
                unitConfig.RequiresMountsFor = [ config.homelab.media.root ];
                # Group-writable files, like the folders they land in.
                serviceConfig.UMask = lib.mkForce "0002";
            };

            networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.settings.general.port ];

            # Languages, providers and their logins, and the Sonarr/Radarr connections.
            homelab.backup.paths = [ cfg.dataDir ];
        };
}
