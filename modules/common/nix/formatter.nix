_:

{
    # nixfmt and treefmt on every host, so `nixfmt` and `treefmt` work outside dev shells too.
    # Both read the repo's treefmt.toml (width 100, indent 4) when run inside it.
    flake.modules.homeManager.common =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                nixfmt
                treefmt
            ];
        };

    # `nix fmt` runs treefmt with the repo's treefmt.toml. pkgs.nixfmt-tree would ignore it
    # and reformat everything with nixfmt's default 2-space indent.
    perSystem =
        { pkgs, ... }:
        {
            formatter = pkgs.writeShellApplication {
                name = "treefmt";
                runtimeInputs = with pkgs; [
                    treefmt
                    nixfmt
                ];
                text = ''exec treefmt "$@"'';
            };
        };
}
