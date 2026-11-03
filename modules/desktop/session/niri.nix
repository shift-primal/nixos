{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop =
        { pkgs, ... }:
        {
            # A second session next to Hyprland (hyprland.nix), configured live from dotfiles/niri.
            # niri-session starts graphical-session.target itself, so unlike Hyprland it needs no UWSM.
            programs.niri.enable = true;

            # niri starts it when an X11 client connects. Steam and most games still need X11.
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
            # Built from vars.keyboard in modules/common/system/locale.nix, plus per-host options.
            inherit (osConfig.services.xserver) xkb;
        in
        {
            dotfiles.links."niri" = "niri";

            # niri can't read vars.lua (theming/vars-lua.nix), so it gets the same values as KDL,
            # included last by dotfiles/niri/config.kdl. niri replaces the whole xkb block on each
            # include, so the layout and the per-host options have to be set together here.
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
            # The keybinds start default apps through ~/.config/nixos-vars/apps/<role>, so the app
            # is still picked in vars.apps.
            // lib.mapAttrs' (
                role: name: lib.nameValuePair "nixos-vars/apps/${role}" { source = lib.getExe pkgs.${name}; }
            ) vars.apps;
        };
}
