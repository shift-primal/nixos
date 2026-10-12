{ pkgs, ... }:

{
    # conform.lua formats markdown with prettier outside ox projects.
    home.packages = with pkgs; [
        prettier
        marksman
    ];
}
