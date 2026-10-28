_:

{
    # Short names on the home LAN for Jellyfin and Seerr (server/local-names.nix announces and routes them).
    flake.modules.nixos.media =
        { config, lib, ... }:
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

            config.homelab.localNames = {
                ${jellyfin} = 8096; # jellyfin.nix
                "req.local" = config.services.seerr.port;
            };
        };
}
