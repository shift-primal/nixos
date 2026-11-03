{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop =
        { pkgs, ... }:
        {

            programs.niri.enable = true;

            environment.systemPackages = with pkgs; [ xwayland-satellite ];
        };

    flake.modules.homeManager.desktop =
        {
            lib,
            osConfig,
            pkgs,
            ...
        }:
        let
            inherit (osConfig.networking) hostName;

            inherit (osConfig.services.xserver) xkb;
        in
        {
            dotfiles.links."niri" = "niri";

            xdg.configFile = {
                "nixos-vars/vars.kdl".text = ''
                    // Generated from ~/nixos/modules/flake/vars.nix. Edit that file and rebuild.
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

                    // Per-machine settings (monitors), loaded last so they win.
                    include "${vars.flakeDir}/dotfiles/niri/hosts/${hostName}.kdl"
                '';
            }

            // lib.mapAttrs' (
                role: name: lib.nameValuePair "nixos-vars/apps/${role}" { source = lib.getExe pkgs.${name}; }
            ) vars.apps;
        };
}
