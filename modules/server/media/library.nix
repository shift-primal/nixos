{ config, ... }:

let
    inherit (config) vars;
in
{
    # Folders and permissions the whole media stack shares: Jellyfin reads the libraries, Decypharr
    # puts symlinks into its mount in downloads/, Sonarr and Radarr move them into the libraries.
    # Files copied in by hand go straight into the libraries.
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
