{ pkgs, ... }:

{
    # conform.lua formats markdown with prettier outside ox projects.
    home.packages = [ pkgs.prettier ];
}
