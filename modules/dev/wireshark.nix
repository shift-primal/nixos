{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.dev =
        { pkgs, ... }:
        {
            # Creates the wireshark group, which gives capture rights.
            programs.wireshark = {
                enable = true;
                package = pkgs.wireshark;
            };
            users.users.${vars.user.name}.extraGroups = [ "wireshark" ];
        };
}
