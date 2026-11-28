{
    flake.modules.nixos.niri =
        {
            config,
            lib,
            pkgs,
            link,
            vars,
            ...
        }:
        let
            inherit (config.services.xserver) xkb;
            apps = lib.mapAttrs (_: name: pkgs.${name}.meta.mainProgram) vars.apps;
            spawnArgs = lib.concatMapStringsSep " " builtins.toJSON;
            spawnBind = key: title: args: ''
                ${key} repeat=false hotkey-overlay-title="${title}" { spawn ${spawnArgs args}; }
            '';
            inTerminal = app: [
                apps.terminal
                "-e"
                app
            ];
        in
        {
            programs.niri = {
                enable = true;
                useNautilus = false;
            };

            hm.home.packages = with pkgs; [
                xwayland-satellite
                wtype
            ];

            hm.xdg.configFile = {
                "niri".source = link "niri";
                "nixos-vars/niri.kdl".text = ''
                    input {
                        keyboard {
                            xkb {
                                layout "${xkb.layout}"
                                variant "${xkb.variant}"
                                options "${xkb.options}"
                            }
                        }
                    }

                    cursor {
                        xcursor-theme "${vars.cursor.name}"
                        xcursor-size ${toString vars.cursor.size}
                    }

                    binds {
                    ${lib.concatStrings [
                        (spawnBind "Mod+Return" "Terminal" [ apps.terminal ])
                        (spawnBind "Mod+E" "File explorer" [ apps.explorer ])
                        (spawnBind "Mod+Shift+N" "Text editor" (inTerminal apps.editor))
                        (spawnBind "Mod+Shift+B" "Web browser" [ apps.browser ])
                        (spawnBind "Mod+Shift+D" "Discord" [ apps.discord ])
                        (spawnBind "Mod+Shift+E" "Email" [ apps.email ])
                        (spawnBind "Mod+Shift+M" "Spotify" (inTerminal apps.spotify))
                    ]}
                    }

                    include "${vars.flakeDir}/dotfiles/niri/hosts/${config.networking.hostName}.kdl"
                '';
            };
        };
}
