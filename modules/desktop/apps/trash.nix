_:

{
    flake.modules.homeManager.desktop = {
        # Empty anything that has sat in the trash for over a week. Moving a file to the trash
        # updates its ctime, so the age counts from when it was trashed.
        systemd.user.tmpfiles.rules = [
            "e %h/.local/share/Trash/files - - - 7d"
            "e %h/.local/share/Trash/info - - - 7d"
        ];
    };
}
