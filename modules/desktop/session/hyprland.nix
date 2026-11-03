_:

{
    flake.modules.nixos.desktop = {

        programs = {
            hyprland = {
                enable = true;
                xwayland.enable = true;
                withUWSM = true;
            };

            gpu-screen-recorder.enable = true;
            dconf.enable = true;
        };

        services = {
            upower.enable = true;
            power-profiles-daemon.enable = true;
        };

        environment.sessionVariables = {
            NIXOS_OZONE_WL = "1";
            XDG_SESSION_TYPE = "wayland";
        };
    };
}
