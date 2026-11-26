{
    flake.modules.nixos.peripherals =
        { pkgs, vars, ... }:
        {
            hardware.bluetooth.enable = true;

            programs.solaar.enable = true;

            hardware.i2c.enable = true;
            users.users.${vars.user.name}.extraGroups = [ "i2c" ];
            environment.systemPackages = [ pkgs.ddcutil ];

            services.fwupd.enable = true;
        };
}
