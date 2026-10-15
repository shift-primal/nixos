{ pkgs, ... }:

{
    imports = [ ./defaults.nix ];

    home.packages = with pkgs; [
        bitwarden-desktop
        filezilla
        vlc
        mpv
        inkscape
    ];
}
