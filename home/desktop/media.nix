{ pkgs, ... }:

{
  home.packages = with pkgs; [
    easyeffects # audio effects, runs as a service from autostart.lua
    v4l-utils # webcam controls, autostart.lua turns off autofocus
    slurp # region picker for the screen recording keybind
  ];
}
