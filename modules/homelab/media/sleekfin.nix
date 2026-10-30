_:

{
    flake.modules.nixos.homelab =
        { pkgs, ... }:
        {
            homelab.media.jellyfinPlugins = with pkgs; [
                jellyfin-plugin-file-transformation
                jellyfin-plugin-sleekfin
            ];
        };
}
