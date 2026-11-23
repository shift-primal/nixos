{
    config,
    lib,
    pkgs,
    vars,
    ...
}:

{
    imports = [
        ./hardware-configuration.nix
        ../../system.nix
        ../../packages
        ../../desktop.nix
        ../../hardware.nix
        ../../dev.nix
        ../../home.nix
    ];

    networking.hostName = "kash-laptop";
    system.stateVersion = "26.05";

    boot = {
        loader.systemd-boot = {
            enable = true;
            configurationLimit = 10;
        };
        loader.timeout = 0;
        initrd.kernelModules = [ "i915" ];
    };

    fileSystems."/boot".options = lib.mkForce [
        "fmask=0077"
        "dmask=0077"
    ];

    hardware.graphics = {
        enable = true;
        extraPackages = [ pkgs.intel-media-driver ];
    };
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
    services = {
        xserver.xkb.options = "caps:swapescape";

        greetd.settings.initial_session = {
            command = "${lib.getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";
            user = vars.user.name;
        };
    };

    assertions = [
        {
            assertion = config.boot.initrd.luks.devices != { };
            message = "greetd autologin needs an encrypted root: set up LUKS first (boot.initrd.luks.devices).";
        }
    ];

    home-manager.users.${vars.user.name} =
        { config, lib, ... }:
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
            home.activation.seedLoginKeyring = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                keyrings="${config.xdg.dataHome}/keyrings"
                if [ ! -e "$keyrings/login.keyring" ]; then
                    run mkdir -p -m 700 "$keyrings"
                    run install -m 600 ${emptyKeyring} "$keyrings/login.keyring"
                    [ -e "$keyrings/default" ] || run sh -c "echo login > '$keyrings/default'"
                fi
            '';
        };
}
