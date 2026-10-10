{ pkgs, ... }:

{
    # nvim-treesitter builds parsers with the tree-sitter CLI and gcc (c.nix).
    home.packages = [ pkgs.tree-sitter ];
}
