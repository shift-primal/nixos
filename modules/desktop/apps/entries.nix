_:

{
    flake.modules.homeManager.desktop =
        { lib, ... }:
        let

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
        };
}
