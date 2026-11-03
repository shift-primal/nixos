{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop = {
        hardware.i2c.enable = true;
        users.users.${vars.user.name}.extraGroups = [ "i2c" ];
    };
}
