{
    flake.modules.nixos.autologin =
        {
            config,
            lib,
            pkgs,
            vars,
            ...
        }:
        let
            emptyKeyring = pkgs.writeText "login.keyring" ''
                [keyring]
                display-name=Login
                ctime=0
                mtime=0
                lock-on-idle=false
                lock-timeout=0
            '';
        in
        {
            services.greetd.settings.initial_session = {
                command = "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";
                user = vars.user.name;
            };

            assertions = [
                {
                    assertion = config.boot.initrd.luks.devices != { };
                    message = "greetd autologin needs an encrypted root: set up LUKS first (boot.initrd.luks.devices).";
                }
            ];

            hm =
                { config, lib, ... }:
                {
                    home.activation.seedLoginKeyring = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                        keyrings="${config.xdg.dataHome}/keyrings"
                        if [ ! -e "$keyrings/login.keyring" ]; then
                            run mkdir -p -m 700 "$keyrings"
                            run install -m 600 ${emptyKeyring} "$keyrings/login.keyring"
                            [ -e "$keyrings/default" ] || run sh -c "echo login > '$keyrings/default'"
                        fi
                    '';
                };
        };
}
