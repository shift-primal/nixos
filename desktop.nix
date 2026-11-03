{
    lib,
    pkgs,
    inputs,
    vars,
    ...
}:

let
    claude-desktop = pkgs.symlinkJoin {
        name = "claude-desktop";
        paths = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/claude-desktop --add-flags "--password-store=gnome-libsecret"
        '';
    };

    reboot-to = pkgs.writeShellScriptBin "reboot-to" ''
        case "$1" in
            windows) label="Windows Boot Manager" ;;
            arch)    label="GRUB" ;;
            limine)  label="Limine" ;;
            *) echo "usage: reboot-to windows|arch|limine" >&2; exit 1 ;;
        esac
        num=$(${lib.getExe pkgs.efibootmgr} | ${lib.getExe pkgs.gnused} -n "s/^Boot\([0-9A-F]\{4\}\)\*\? $label.*/\1/p" | head -n1)
        [ -n "$num" ] || { echo "no UEFI entry named '$label'" >&2; exit 1; }
        ${lib.getExe pkgs.efibootmgr} --bootnext "$num" >/dev/null
        systemctl reboot
    '';
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
        steam.enable = true;
    };

    services = {
        upower.enable = true;
        power-profiles-daemon.enable = true;
    };

    environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        XDG_SESSION_TYPE = "wayland";
    };

    services.displayManager.noctalia-greeter = {
        enable = true;
        settings = {
            session.default = "Hyprland";
            keyboard.layout = vars.keyboard.layout;
            cursor.size = vars.cursor.size;
        };
    };

    xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    services.gnome.gnome-keyring.enable = true;
    services.gnome.gcr-ssh-agent.enable = false;
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
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        corefonts
        monaspace
    ];

    environment.systemPackages = [
        claude-desktop
        reboot-to
    ];

    security.sudo.extraRules = [
        {
            users = [ vars.user.name ];
            commands = [
                {
                    command = "/run/current-system/sw/bin/reboot-to";
                    options = [ "NOPASSWD" ];
                }
            ];
        }
    ];

    home-manager.users.${vars.user.name} = {
        imports = [ inputs.noctalia.homeModules.default ];

        programs.noctalia.enable = true;

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
                    "nvidia-settings"
                    "uuctl"
                ]
                (id: {
                    name = id;
                    exec = id;
                    noDisplay = true;
                });

        systemd.user.tmpfiles.rules = [
            "e %h/.local/share/Trash/files - - - 7d"
            "e %h/.local/share/Trash/info - - - 7d"
        ];
    };
}
