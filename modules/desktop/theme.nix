{
    flake.modules.nixos.theme =
        { pkgs, vars, ... }:
        {
            hm = {
                home.pointerCursor = {
                    enable = true;
                    package = pkgs.${vars.cursor.package};
                    inherit (vars.cursor) name size;
                    gtk.enable = true;
                    x11.enable = true;
                };

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
            };
        };
}
