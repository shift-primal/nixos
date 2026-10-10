{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
    cliphist
    wl-clip-persist
    slurp
    easyeffects
    v4l-utils
  ];
}
