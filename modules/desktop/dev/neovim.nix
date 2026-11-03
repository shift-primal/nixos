_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                tree-sitter
                gcc
            ];
            dotfiles.links.nvim = "nvim";
        };
}
