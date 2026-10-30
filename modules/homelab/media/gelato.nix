_:

{
    # Gelato: a Jellyfin plugin that makes everything AIOStreams (aiostreams.nix) knows browsable and
    # searchable in Jellyfin, on every client. Pressing play asks AIOStreams for the best release
    # Real-Debrid has and streams it, so nothing has to be requested first. Its titles live in folders
    # of their own inside the Filmer and Serier libraries; media-configure (configure.nix) sets the
    # plugin up and adds those folders.
    flake.modules.nixos.homelab =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            inherit (config.services.jellyfin) dataDir;
            folders = "${dataDir}/gelato";
        in
        {
            options.homelab.media.gelato = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = {
                    pluginId = "94ea4e14-8163-4989-96fe-0a2094bc2d6a";
                    moviePath = "${folders}/movies";
                    seriesPath = "${folders}/series";
                };
                readOnly = true;
                description = "Gelato's plugin id and title folders, for media-configure (configure.nix).";
            };

            config = {
                homelab.media.jellyfinPlugins = [ pkgs.jellyfin-plugin-gelato ];

                systemd.tmpfiles.settings.gelato =
                    lib.genAttrs [ folders "${folders}/movies" "${folders}/series" ]
                        (_: {
                            d = {
                                user = config.services.jellyfin.user;
                                inherit (config.services.jellyfin) group;
                                mode = "0750";
                            };
                        });
            };
        };
}
