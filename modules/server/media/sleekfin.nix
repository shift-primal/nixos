_:

{
    flake.modules.nixos.media =
        { pkgs, ... }:
        {
            homelab.media.jellyfinPlugins = with pkgs; [
                jellyfin-plugin-file-transformation
                jellyfin-plugin-sleekfin
            ];
        };
}
