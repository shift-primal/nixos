{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.homeManager.workstation =
        { lib, pkgs, ... }:
        {
            # Default apps (terminal, browser, email, ...) are picked in modules/flake/vars.nix.
            # Installed here so a keybind can never point at an app that isn't installed.
            home.packages = map (name: pkgs.${name}) (lib.attrValues vars.apps);
        };
}
