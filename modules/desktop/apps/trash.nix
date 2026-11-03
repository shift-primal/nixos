_:

{
    flake.modules.homeManager.desktop = {

        systemd.user.tmpfiles.rules = [
            "e %h/.local/share/Trash/files - - - 7d"
            "e %h/.local/share/Trash/info - - - 7d"
        ];
    };
}
