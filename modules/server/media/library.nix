{ config, ... }:

let
    inherit (config) vars;
in
{
    # Folders and permissions the whole media stack shares: Jellyfin reads the libraries, qBittorrent
    # writes downloads, Sonarr and Radarr hardlink finished downloads into the libraries. Hardlinks
    # only work within one filesystem, so downloads and libraries live under the same root.
    flake.modules.nixos.media =
        { config, lib, ... }:
        let
            inherit (config.homelab.media) root;
        in
        {
            options.homelab.media.root = lib.mkOption {
                type = lib.types.str;
                description = "Disk holding media/ (libraries) and downloads/.";
                example = "/mnt/data";
            };

            config = {
                # Fixed gid: the qBittorrent container (qbittorrent.nix) gets it as a number.
                users.groups.media = {
                    gid = 2000;
                    members = [ vars.user.name ];
                };

                # Group-writable and setgid, so every service and the user (copying files in over
                # SSH) can manage what the others wrote.
                systemd.tmpfiles.settings.media =
                    lib.genAttrs
                        (map (dir: "${root}/${dir}") [
                            "media"
                            "media/movies"
                            "media/shows"
                            "media/music"
                            "downloads"
                        ])
                        (_: {
                            d = {
                                user = vars.user.name;
                                group = "media";
                                mode = "2775";
                            };
                        });
            };
        };
}
