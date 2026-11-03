{ config, ... }:

let
    inherit (config) vars;
in
{

    flake.modules.homeManager.desktop =
        {
            lib,
            osConfig,
            pkgs,
            ...
        }:
        let
            luaVars = {
                inherit (vars) keyboard;
                hostname = osConfig.networking.hostName;
                cursor = { inherit (vars.cursor) name size; };
                apps = lib.mapAttrs (_: name: pkgs.${name}.meta.mainProgram) vars.apps;
            };
        in
        {
            xdg.configFile."nixos-vars/vars.lua".text = ''
                -- Generated from ~/nixos/modules/flake/vars.nix. Edit that file and rebuild.
                return ${lib.generators.toLua { } luaVars}
            '';
        };
}
