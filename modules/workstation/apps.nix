_:

{
    flake.modules.homeManager.workstation =
        { pkgs, ... }:
        let
            # OnlyOffice ignores fontconfig and won't follow symlinked fonts, so the package copies
            # these into its own font dir. corefonts gives Office documents their Arial/Times/etc.
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
                libreoffice-fresh
            ];
        };
}
