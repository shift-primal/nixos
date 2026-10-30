_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            # nvim-treesitter compiles parsers with tree-sitter, which needs a C compiler.
            home.packages = with pkgs; [
                tree-sitter
                gcc
            ];
            dotfiles.links.nvim = "nvim";
        };
}
