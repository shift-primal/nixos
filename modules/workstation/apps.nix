_:

{
    flake.modules.homeManager.workstation =
        { pkgs, ... }:
        let
            # Sync client for OpenCloud on the homelab (modules/server/opencloud.nix), started from
            # autostart.lua. Its QML window aborts on the adwaita Qt theme from theme.nix ("module
            # adwaita-dark is not installed"), so it runs without it. The package also ships a second
            # launcher with the same name, which is dropped.
            opencloud = pkgs.symlinkJoin {
                name = "opencloud-desktop";
                paths = [ pkgs.opencloud-desktop ];
                nativeBuildInputs = [ pkgs.makeWrapper ];
                postBuild = ''
                    for bin in opencloud opencloudcmd; do
                        wrapProgram $out/bin/$bin --unset QT_STYLE_OVERRIDE --unset QT_QPA_PLATFORMTHEME
                    done
                    rm $out/share/applications/opencloudcmd.desktop
                '';
            };
        in
        {
            home.packages = with pkgs; [
                bitwarden-desktop
                obsidian
                filezilla
                vlc
                mpv
                inkscape
                opencloud
            ];
        };
}
