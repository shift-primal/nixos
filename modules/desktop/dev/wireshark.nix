{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop =
        { pkgs, ... }:
        {
            programs.wireshark = {
                enable = true;
                package = pkgs.wireshark;
            };
            users.users.${vars.user.name}.extraGroups = [ "wireshark" ];
        };
}
