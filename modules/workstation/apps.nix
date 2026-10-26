_:

{
    flake.modules.homeManager.workstation =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                bitwarden-desktop
                obsidian
                filezilla
                vlc
                mpv
                inkscape
            ];
        };
}
