{ vars, ... }:

{
    # Login screen for every host. Per-host autologin is added in hosts/<hostname>/greetd.nix.
    # The greeter lists the sessions installed by programs.hyprland (including the UWSM one).
    services.displayManager.noctalia-greeter = {
        enable = true;
        settings = {
            # The plain "Hyprland" entry skips graphical-session.target, so xdg-desktop-portal
            # (file pickers, screen sharing) refuses to start. Pre-select the UWSM one.
            session.default = "Hyprland (uwsm-managed)";
            keyboard.layout = vars.keyboard.layout;
            cursor.size = vars.cursor.size;
        };
    };
}
