{ pkgs, ... }:

{
    # conform.lua formats markdown with prettier, not oxfmt.
    home.packages = with pkgs; [
        prettier
        marksman
    ];
}
