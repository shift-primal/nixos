{
    flake.overlays.default = import ../../pkgs;

    perSystem =
        { pkgs, ... }:
        {
            formatter = pkgs.writeShellApplication {
                name = "treefmt";
                runtimeInputs = [
                    pkgs.treefmt
                    (pkgs.callPackage ../../pkgs/nixfmt.nix { })
                ];
                text = ''exec treefmt "$@"'';
            };
        };
}
