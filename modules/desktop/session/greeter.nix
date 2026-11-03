{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop = {

        services.displayManager.noctalia-greeter = {
            enable = true;
            settings = {
                session.default = "Hyprland";
                keyboard.layout = vars.keyboard.layout;
                cursor.size = vars.cursor.size;
            };
        };
    };
}
