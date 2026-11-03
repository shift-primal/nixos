{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.homeManager.desktop =
        { lib, pkgs, ... }:
        {

            home.packages = map (name: pkgs.${name}) (lib.attrValues vars.apps);
        };
}
