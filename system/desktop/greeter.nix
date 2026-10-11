{ vars, ... }:

{
    # Login screen for every host. Per-host autologin is added in hosts/<hostname>/greetd.nix.
    # The greeter lists the sessions installed by programs.hyprland (including the UWSM one).
    services.displayManager.noctalia-greeter = {
        enable = true;
        settings = {
            keyboard.layout = vars.keyboard.layout;
            cursor.size = vars.cursor.size;
        };
    };
}
