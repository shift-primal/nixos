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
            # Packages from pkgs/ (modules/flake/overlay.nix), available as pkgs.<name> in every module.
            overlays = [ default ];
        };
    };
}
