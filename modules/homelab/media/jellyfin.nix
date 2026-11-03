_:

{

    flake.modules.nixos.homelab =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            inherit (config.services.jellyfin) dataDir;
        in
        {
            options.homelab.media.jellyfinPlugins = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = "Plugins (with passthru.pluginName) installed into Jellyfin's plugin folder.";
            };

            config = {
                services.jellyfin.enable = true;

                services.jellyfin.package = pkgs.jellyfin.overrideAttrs (prev: {
                    patches = (prev.patches or [ ]) ++ [
                        ./_jellyfin-norwegian.patch
                        ./_jellyfin-search.patch
                    ];
                });
                users.users.jellyfin.extraGroups = [ "media" ];

                networking.firewall = {
                    allowedTCPPorts = [ 8096 ];
                    allowedUDPPorts = [ 7359 ];
                };

                systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ config.homelab.media.root ];

                homelab.backup.paths = [ dataDir ];

                systemd.services.jellyfin.preStart = lib.mkBefore (
                    lib.concatMapStrings (plugin: ''
                        dir="${dataDir}/plugins/${plugin.pluginName}_${plugin.version}"
                        if [ ! -e "$dir/meta.json" ]; then
                            rm -rf "${dataDir}/plugins/${plugin.pluginName}_"*
                            mkdir -p "${dataDir}/plugins"
                            cp -r ${plugin} "$dir"
                            chmod -R u+w "$dir"
                        fi
                    '') config.homelab.media.jellyfinPlugins
                );
            };
        };
}
