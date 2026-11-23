{ inputs, pkgs, ... }:

{
    imports = [ inputs.artcraft.nixosModules.default ];

    programs.artcraft = {
        enable = true;
        apps = [
            "photocraft"
            "vectorcraft"
        ];
    };

    environment.systemPackages = with pkgs; [
        bitwarden-desktop
        filezilla
        vlc
        mpv
        (onlyoffice-desktopeditors.override { extraFontPackages = [ corefonts ]; })
    ];
}
