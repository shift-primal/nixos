{ pkgs, ... }:

{
  imports = [ ./defaults.nix ];

  home.packages = with pkgs; [
    chromium
    bitwarden-desktop
    filezilla
    vlc
  ];
}
