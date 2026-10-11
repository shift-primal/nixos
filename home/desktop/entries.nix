{ lib, ... }:

let
    # Desktop entries to hide from the launcher.
    hidden = [
        "qv4l2"
        "qvidcap"
        "nvidia-settings"
        "uuctl"
    ];
in
{
    xdg.desktopEntries = lib.genAttrs hidden (id: {
        name = id;
        exec = id;
        noDisplay = true;
    });
}
