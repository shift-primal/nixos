{ pkgs, ... }:

{
    programs.steam.enable = true;

    environment.systemPackages = with pkgs; [
        bolt-launcher
        lutris
        wowup-cf
    ];
}
