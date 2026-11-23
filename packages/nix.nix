{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        nixfmt-wrapped
        treefmt
        nil
        statix
        lua-language-server
        stylua
        tombi
        sops
        age
        tree-sitter
        gcc
    ];
}
