{ pkgs, ... }:

{
  # conform.lua formats toml with tombi.
  home.packages = [ pkgs.tombi ];
}
