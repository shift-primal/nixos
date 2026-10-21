{ pkgs, ... }:

{
    imports = [ ./default-apps.nix ];

    home.packages = with pkgs; [
        bitwarden-desktop
        obsidian
        filezilla
        vlc
        mpv
        inkscape
    ];
}
