_:

{
    flake.modules.homeManager.dev =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.tree-sitter ];
            dotfiles.links.nvim = "nvim";
        };
}
