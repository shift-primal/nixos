_:

let
    # nixfmt has no config file, so the style is baked into the binary. Every nixfmt on PATH
    # (Neovim, treefmt, `nix fmt`, projects made from templates/) formats the same way.
    # The indent is mirrored in dotfiles/nvim/lua/config/autocmds.lua.
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

    # `nix fmt` runs treefmt with the repo's treefmt.toml and the nixfmt above.
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
