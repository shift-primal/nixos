{ pkgs, ... }:

let
  betterbird = pkgs.writeShellScriptBin "betterbird" ''
    exec ${pkgs.thunderbird}/bin/thunderbird "$@"
  '';
in

{
  home.packages = with pkgs; [
    firefox
    vesktop
    spotify-player
    bitwarden-desktop
    thunderbird
    betterbird
  ];
}
