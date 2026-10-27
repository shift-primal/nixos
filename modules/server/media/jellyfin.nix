_:

{
    # Jellyfin, reachable from the home LAN and the tailnet but not the internet: streaming video
    # through the Cloudflare tunnel breaks Cloudflare's terms, so it gets no Caddy vhost. Open
    # http://<hostname>:8096.
    # The GPU side (VA-API, codecs) is per machine: modules/hosts/kash-homelab/intel.nix.
    flake.modules.nixos.media =
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
                # Jellyfin picks a subtitle or audio track only when its language code equals the
                # preference exactly, but releases tag Norwegian as nor, nob, nno, no or nb; the patch
                # makes any of them match. It also takes a fallback list ("nor,eng" in configure.nix),
                # which Jellyfin's single preference can't. Built from source, so it takes a while
                # after a nixpkgs bump.
                services.jellyfin.package = pkgs.jellyfin.overrideAttrs (prev: {
                    patches = (prev.patches or [ ]) ++ [ ./_jellyfin-norwegian.patch ];
                });
                users.users.jellyfin.extraGroups = [ "media" ];

                # Open on every interface, so the TVs at home need no Tailscale. The router forwards no
                # ports, so that means the LAN and the tailnet. UDP 7359 lets apps on the LAN find it.
                networking.firewall = {
                    allowedTCPPorts = [ 8096 ];
                    allowedUDPPorts = [ 7359 ];
                };

                # The media disk is mounted nofail. Without it a library scan would find empty folders
                # and drop every item, so Jellyfin waits for the mount instead.
                systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ config.homelab.media.root ];

                # Config, users, watch history and fetched metadata. The media itself is not copied
                # off-site (backup.nix); the cache dir is outside this path.
                homelab.backup.paths = [ dataDir ];

                # Jellyfin writes each plugin's state into its folder, so it gets a copy rather than a
                # link into the store. A new version replaces the old folder. mkBefore: the module's own
                # preStart can exit early.
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
