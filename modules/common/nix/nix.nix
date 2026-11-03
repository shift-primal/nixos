{ config, ... }:

let
    inherit (config.flake.overlays) default;
in
{
    flake.modules.nixos.common = {
        nix.settings.experimental-features = [
            "nix-command"
            "flakes"
        ];

        nixpkgs = {
            config.allowUnfree = true;

            overlays = [ default ];
        };
    };
}
