_:

{
    # Gelato: a Jellyfin plugin that makes everything AIOStreams (aiostreams.nix) knows browsable and
    # searchable in Jellyfin, on every client. Pressing play asks AIOStreams for the best release
    # Real-Debrid has and streams it, so nothing has to be requested first. Its titles live in folders
    # of their own inside the Filmer and Serier libraries; media-configure (configure.nix) sets the
    # plugin up and adds those folders. gelato-promote.nix turns a played title into a real one.
    flake.modules.nixos.media =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            plugin = pkgs.jellyfin-plugin-gelato;
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
                # Jellyfin writes the plugin's state into its folder, so it gets a copy rather than
                # a link into the store. A new version replaces the old folder.
                systemd.services.jellyfin.preStart = lib.mkBefore ''
                    plugin=${dataDir}/plugins/Gelato_${plugin.version}
                    if [ ! -e "$plugin/Gelato.dll" ]; then
                        rm -rf ${dataDir}/plugins/Gelato_*
                        mkdir -p ${dataDir}/plugins
                        cp -r ${plugin} "$plugin"
                        chmod -R u+w "$plugin"
                    fi
                '';

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
