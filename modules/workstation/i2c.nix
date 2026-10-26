{ config, ... }:

let
    inherit (config) vars;
in
{
    # ddcutil talks to monitors over /dev/i2c-*.
    flake.modules.nixos.workstation = {
        hardware.i2c.enable = true;
        users.users.${vars.user.name}.extraGroups = [ "i2c" ];
    };
}
