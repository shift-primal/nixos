{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop.home-manager.users.${vars.user.name}.imports = [
        config.flake.modules.homeManager.desktop
    ];
}
