{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.kash-laptop =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let

            session = "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";
        in
        {

            assertions = [
                {
                    assertion = config.boot.initrd.luks.devices != { };
                    message = "greetd autologin needs an encrypted root: set up LUKS first (boot.initrd.luks.devices).";
                }
            ];

            services.greetd.settings.initial_session = {
                command = session;
                user = vars.user.name;
            };
        };
}
