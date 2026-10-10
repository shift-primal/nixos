_:

{
    nix.settings.experimental-features = [
        "nix-command"
        "flakes"
    ];

    nixpkgs = {
        config.allowUnfree = true;
        # Packages from pkgs/, available as pkgs.<name> in every module.
        overlays = [ (import ../../pkgs) ];
    };
}
