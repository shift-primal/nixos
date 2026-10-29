{ config, ... }:

let
    inherit (config) vars;
in
{
    # The library folders Jellyfin reads, next to Gelato's own (gelato.nix). Files copied in by hand
    # go straight into them.
    flake.modules.nixos.media =
        { config, lib, ... }:
        let
            inherit (config.homelab.media) root;
        in
        {
            options.homelab.media.root = lib.mkOption {
                type = lib.types.str;
                description = "Disk holding media/ (the libraries).";
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
