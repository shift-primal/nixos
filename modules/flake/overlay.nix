_:

{
    # Packages from pkgs/, applied to every host in modules/base/nix.nix.
    flake.overlays.default = import ../../pkgs;
}
