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
                # Sync client for OpenCloud on the homelab (modules/server/opencloud.nix), started
                # from autostart.lua.
                opencloud-desktop
            ];
        };
}
