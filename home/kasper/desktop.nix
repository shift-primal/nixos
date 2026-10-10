{ lib, pkgs, ... }:
let
  hidden = [
    "qv4l2"
    "qvidcap"
    "nvidia-settings"
  ];
in
{
  xdg.desktopEntries = lib.listToAttrs (
    map (id: {
      name = id;
      value = {
        name = id;
        exec = id;
        noDisplay = true;
      };
    }) hidden
  );

  fonts.fontconfig.enable = true;
  home.packages = [ pkgs.monaspace ];

  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
