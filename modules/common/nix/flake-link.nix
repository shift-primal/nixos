{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.common = {

        systemd.tmpfiles.rules = [ "L /etc/nixos - - - - ${vars.flakeDir}" ];
    };
}
