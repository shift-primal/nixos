{
    config,
    lib,
    pkgs,
    vars,
    ...
}:

let
    # Same command as the "Hyprland (uwsm-managed)" session from programs.hyprland.withUWSM.
    session = "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";
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

    services.greetd = {
        enable = true;
        settings = {
            initial_session = {
                command = session;
                user = vars.user.name;
            };
            # Shown after logging out of the autologin session.
            default_session = {
                command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd '${session}'";
                user = "greeter";
            };
        };
    };
}
