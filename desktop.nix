{
    lib,
    pkgs,
    inputs,
    vars,
    ...
}:

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

    services = {
        gvfs.enable = true;
        upower.enable = true;
        power-profiles-daemon.enable = true;

        displayManager.noctalia-greeter = {
            enable = true;
            settings = {
                session.default = "Hyprland";
                keyboard.layout = vars.keyboard.layout;
                cursor.size = vars.cursor.size;
            };
        };

        gnome.gnome-keyring.enable = true;
        gnome.gcr-ssh-agent.enable = false;
    };

    xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
    security.pam.services.greetd.enableGnomeKeyring = true;

    boot = {
        plymouth = {
            enable = true;
            theme = "nixos-bgrt";
            themePackages = [ pkgs.nixos-bgrt-plymouth ];
        };
        consoleLogLevel = 3;
        kernelParams = [
            "quiet"
            "splash"
            "udev.log_level=3"
            "systemd.show_status=auto"
        ];
    };

    fonts.packages = with pkgs; [
        (google-fonts.override { fonts = [ "Figtree" ]; })
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        corefonts
        monaspace
    ];

    home-manager.users.${vars.user.name} = {
        imports = [
            inputs.noctalia.homeModules.default
            inputs.luciole.homeModules.default
        ];

        programs = {
            noctalia.enable = true;
            luciole.enable = true;
        };

        home.sessionVariables.SUDO_ASKPASS = "${pkgs.writeShellScript "sudo-askpass" ''
            exec ${lib.getExe pkgs.zenity} --password --title="sudo"
        ''}";

        home.pointerCursor = {
            enable = true;
            package = pkgs.${vars.cursor.package};
            inherit (vars.cursor) name size;
            gtk.enable = true;
            x11.enable = true;
        };

        fonts.fontconfig.enable = true;

        dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

        gtk = {
            enable = true;
            theme = {
                name = "Adwaita-dark";
                package = pkgs.gnome-themes-extra;
            };
            iconTheme = {
                name = "Gruvbox-Plus-Dark";
                package = pkgs.gruvbox-plus-icons;
            };
            gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
            gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
        };

        qt = {
            enable = true;
            platformTheme.name = "qtct";
            qt5ctSettings.Appearance = {
                style = "Fusion";
                custom_palette = true;
                color_scheme_path = "${vars.user.home}/.config/qt5ct/colors/noctalia.conf";
                icon_theme = "Gruvbox-Plus-Dark";
            };
            qt6ctSettings.Appearance = {
                style = "Fusion";
                custom_palette = true;
                color_scheme_path = "${vars.user.home}/.config/qt6ct/colors/noctalia.conf";
                icon_theme = "Gruvbox-Plus-Dark";
            };
        };

        xdg.desktopEntries =
            lib.genAttrs
                [
                    "qv4l2"
                    "qvidcap"
                    "uuctl"
                ]
                (id: {
                    name = id;
                    exec = id;
                    noDisplay = true;
                });

        systemd.user.services.bitwarden = {
            Unit = {
                Description = "Bitwarden (SSH agent)";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
            };
            Service = {
                ExecStart = lib.getExe pkgs.bitwarden-desktop;
                Restart = "on-failure";
                RestartSec = 3;
            };
            Install.WantedBy = [ "graphical-session.target" ];
        };

        systemd.user.tmpfiles.rules = [
            "e %h/.local/share/Trash/files - - - 7d"
            "e %h/.local/share/Trash/info - - - 7d"
        ];
    };
}
