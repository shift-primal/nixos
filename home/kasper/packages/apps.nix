{ pkgs, ... }:

{
  home.packages = with pkgs; [
    firefox
    chromium
    vesktop
    spotify-player
    bitwarden-desktop
    thunderbird
    filezilla
    vlc
  ];
}
