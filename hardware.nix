{ pkgs, vars, ... }:

{
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
    };

    hardware.bluetooth.enable = true;

    hardware.i2c.enable = true;
    users.users.${vars.user.name}.extraGroups = [ "i2c" ];

    programs.solaar.enable = true;

    services.printing = {
        enable = true;
        drivers = [ pkgs.hplip ];
    };
    services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
    };

    home-manager.users.${vars.user.name}.services.easyeffects = {
        enable = true;
        preset.input = "Kasper";
    };
}
