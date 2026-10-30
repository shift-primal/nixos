_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.tree-sitter ];
            dotfiles.links.nvim = "nvim";
        };
}
