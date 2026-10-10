{ lib, pkgs, vars, ... }:

{
  # Default apps (terminal, browser, email, ...) are picked in vars.nix.
  # Installed here so a keybind can never point at an app that isn't installed.
  home.packages = map (name: pkgs.${name}) (lib.attrValues vars.apps);
}
