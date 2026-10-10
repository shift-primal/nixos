{ pkgs, ... }:

{
    home.packages = with pkgs; [
        nil
        nixfmt
        treefmt
        statix
    ];
}
