_:

{
    # Jellyfin's short name on the home LAN (server/local-names.nix announces and routes it).
    flake.modules.nixos.media =
        { lib, ... }:
        let
            jellyfin = "snyltflix.local";
        in
        {
            options.homelab.media.jellyfinUrl = lib.mkOption {
                type = lib.types.str;
                default = "http://${jellyfin}";
                readOnly = true;
                description = "Jellyfin's address on the home LAN, for links to it (configure.nix).";
            };

            config.homelab.localNames.${jellyfin} = 8096; # jellyfin.nix
        };
}
