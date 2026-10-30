{ config, ... }:

let
    inherit (config) vars;
in
{
    # Home Manager side of this aspect, for hosts that import it (see common/home-manager.nix).
    flake.modules.nixos.desktop.home-manager.users.${vars.user.name}.imports = [
        config.flake.modules.homeManager.desktop
    ];
}
