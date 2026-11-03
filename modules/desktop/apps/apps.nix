_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        let

            onlyoffice = pkgs.onlyoffice-desktopeditors.override {
                extraFontPackages = with pkgs; [ corefonts ];
            };
        in
        {
            home.packages = with pkgs; [
                bitwarden-desktop
                obsidian
                filezilla
                vlc
                mpv
                inkscape
                onlyoffice
                libreoffice
            ];
        };
}
