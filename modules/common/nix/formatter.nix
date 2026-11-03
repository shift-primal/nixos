_:

let

    nixfmt =
        pkgs:
        pkgs.symlinkJoin {
            name = "nixfmt";
            paths = [ pkgs.nixfmt ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
                wrapProgram $out/bin/nixfmt --add-flags "--width=100 --indent=4"
            '';
            meta.mainProgram = "nixfmt";
        };
in
{
    flake.modules.homeManager.common =
        { pkgs, ... }:
        {
            home.packages = [
                (nixfmt pkgs)
                pkgs.treefmt
            ];
        };

    perSystem =
        { pkgs, ... }:
        {
            formatter = pkgs.writeShellApplication {
                name = "treefmt";
                runtimeInputs = [
                    pkgs.treefmt
                    (nixfmt pkgs)
                ];
                text = ''exec treefmt "$@"'';
            };
        };
}
