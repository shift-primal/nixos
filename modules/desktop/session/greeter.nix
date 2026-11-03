{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop = {
        # Login screen for every host. Per-host autologin is added in modules/hosts/<hostname>/greetd.nix.
        # The greeter lists the sessions installed by programs.niri and programs.hyprland. To go back
        # to Hyprland, pick "Hyprland (uwsm-managed)": the plain "Hyprland" entry skips
        # graphical-session.target, so xdg-desktop-portal (file pickers, screen sharing) refuses to start.
        services.displayManager.noctalia-greeter = {
            enable = true;
            settings = {
                session.default = "Niri";
                keyboard.layout = vars.keyboard.layout;
                cursor.size = vars.cursor.size;
            };
        };
    };
}
