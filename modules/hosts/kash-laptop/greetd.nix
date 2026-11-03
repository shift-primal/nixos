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
            # Same command as the "Niri" session from programs.niri. Back to Hyprland:
            # "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop".
            session = "${lib.getExe' config.programs.niri.package "niri-session"}";
        in
        {
            # Autologin skips the only login prompt, so it is only safe when the disk is encrypted and the
            # LUKS passphrase typed at boot is the authentication.
            assertions = [
                {
                    assertion = config.boot.initrd.luks.devices != { };
                    message = "greetd autologin needs an encrypted root: set up LUKS first (boot.initrd.luks.devices).";
                }
            ];

            # The login screen itself is modules/desktop/session/greeter.nix. After logging out of the
            # autologin session greetd falls back to it.
            services.greetd.settings.initial_session = {
                command = session;
                user = vars.user.name;
            };
        };
}
