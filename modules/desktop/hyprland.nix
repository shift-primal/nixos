{
    flake.modules.nixos.hyprland =
        {
            config,
            lib,
            pkgs,
            link,
            vars,
            ...
        }:
        let
            luaVars = {
                inherit (vars) keyboard;
                hostname = config.networking.hostName;
                cursor = { inherit (vars.cursor) name size; };
                apps = lib.mapAttrs (_: name: pkgs.${name}.meta.mainProgram) vars.apps;
            };
        in
        {
            programs = {
                hyprland = {
                    enable = true;
                    xwayland.enable = true;
                    withUWSM = true;
                };
                gpu-screen-recorder.enable = true;
                dconf.enable = true;
            };

            environment.sessionVariables = {
                NIXOS_OZONE_WL = "1";
                XDG_SESSION_TYPE = "wayland";
            };

            xdg.portal = {
                enable = true;
                extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
            };

            hm.xdg.configFile = {
                "hypr".source = link "hypr";
                "nixos-vars/vars.lua".text = "return ${lib.generators.toLua { } luaVars}\n";
            };
        };
}
