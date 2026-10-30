_:

{
    # Packages from pkgs/, applied to every host in modules/common/nix/nix.nix.
    flake.overlays.default = import ../../pkgs;
}
