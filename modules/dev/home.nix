{ config, ... }:

let
    inherit (config) vars;
in
{
    # Home Manager side of this aspect, for hosts that import it (see base/home-manager.nix).
    flake.modules.nixos.dev.home-manager.users.${vars.user.name}.imports = [
        config.flake.modules.homeManager.dev
    ];
}
