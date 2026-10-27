_:

{
    # SleekFin: a new look for Jellyfin's web interface (home hero, floating header, detail pages). It
    # changes the web files as Jellyfin serves them, through File Transformation, so the TV apps look
    # the same. Its options are under Dashboard > SleekFin.
    flake.modules.nixos.media =
        { pkgs, ... }:
        {
            homelab.media.jellyfinPlugins = with pkgs; [
                jellyfin-plugin-file-transformation
                jellyfin-plugin-sleekfin
            ];
        };
}
