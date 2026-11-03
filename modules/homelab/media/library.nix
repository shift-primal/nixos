{ config, ... }:

let
    inherit (config) vars;
in
{

    flake.modules.nixos.homelab =
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
