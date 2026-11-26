{
    flake.modules.nixos.session =
        { lib, pkgs, ... }:
        {
            services = {
                gvfs.enable = true;
                upower.enable = true;
                power-profiles-daemon.enable = true;
            };

            hm = {
                home.sessionVariables.SUDO_ASKPASS = "${pkgs.writeShellScript "sudo-askpass" ''
                    exec ${lib.getExe pkgs.zenity} --password --title="sudo"
                ''}";

                xdg.desktopEntries =
                    lib.genAttrs
                        [
                            "qv4l2"
                            "qvidcap"
                            "uuctl"
                        ]
                        (id: {
                            name = id;
                            exec = id;
                            noDisplay = true;
                        });

                systemd.user.tmpfiles.rules = [
                    "e %h/.local/share/Trash/files - - - 7d"
                    "e %h/.local/share/Trash/info - - - 7d"
                ];
            };
        };
}
