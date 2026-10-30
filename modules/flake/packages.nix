{ config, inputs, ... }:

let
    overlay = config.flake.overlays.default;
in
{
    # The overlay's packages as flake outputs, so dev templates can use them (templates/node).
    perSystem =
        { lib, system, ... }:
        let
            pkgs = import inputs.nixpkgs {
                inherit system;
                overlays = [ overlay ];
                config.allowUnfree = true;
            };
        in
        {
            packages = lib.getAttrs (builtins.attrNames (import ../../pkgs { } { })) pkgs;
        };
}
