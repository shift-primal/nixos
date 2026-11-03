_:

{
    # Homepage (gethomepage.dev): the homelab's dashboard, replacing homehub. Home LAN and tailnet
    # only, at http://hub.local and http://<hostname> (edge/local-names.nix). Domains and ports are
    # read from the modules that own them, and every app in homelab.apps with a domain gets a tile.
    # The status dots are HTTP checks against 127.0.0.1, made server-side. No widget uses an API
    # key, so nothing here needs sops.
    flake.modules.nixos.homelab =
        { config, lib, ... }:
        let
            cfg = config.services.homepage-dashboard;
            hostName = config.networking.hostName;
            local = port: "http://127.0.0.1:${toString port}";
            tailnetUrl = port: "https://${hostName}.${config.homelab.tailnet}:${toString port}";
            names = [
                "hub.local"
                hostName
            ];

            tile = name: attrs: { ${name} = attrs; };

            apps = lib.mapAttrsToList (
                name: app:
                tile name {
                    href = "https://${app.domain}";
                    description = app.domain;
                    siteMonitor = local app.port;
                    icon = "mdi-web";
                }
            ) (lib.filterAttrs (_: app: app.domain != null) config.homelab.apps);
        in
        {
            services.homepage-dashboard = {
                enable = true;
                # Caddy keeps the Host header, which Homepage checks against this list.
                allowedHosts = lib.concatStringsSep "," (
                    names ++ [ "127.0.0.1:${toString cfg.listenPort}" ]
                );

                settings = {
                    title = hostName;
                    theme = "dark";
                    color = "slate";
                    headerStyle = "clean";
                    statusStyle = "dot";
                    hideVersion = true;
                    layout = {
                        Media = {
                            style = "row";
                            columns = 3;
                        };
                        Homelab = {
                            style = "row";
                            columns = 3;
                        };
                        Apps = {
                            style = "row";
                            columns = 3;
                        };
                    };
                };

                # Runs on the host, so these are the host's own numbers (Beszel keeps the history).
                widgets = [
                    {
                        resources = {
                            label = "System";
                            cpu = true;
                            memory = true;
                            cputemp = true;
                            units = "metric";
                            uptime = true;
                        };
                    }
                    {
                        resources = {
                            label = "Storage";
                            disk = [
                                "/"
                                "/mnt/data"
                            ];
                        };
                    }
                ];

                services = [
                    {
                        Media = [
                            (tile "Jellyfin" {
                                href = "http://snyltflix.local";
                                description = "Snyltflix";
                                # jellyfin.nix
                                siteMonitor = local 8096;
                                icon = "jellyfin.svg";
                            })
                            # Only Jellyfin talks to these two; the tiles are for their status.
                            (tile "AIOStreams" {
                                description = "Streams for Gelato";
                                siteMonitor = config.homelab.media.aiostreams.url;
                                icon = "sh-aiostreams.svg";
                            })
                            (tile "TMDB addon" {
                                description = "Catalogs and search";
                                # tmdb-addon.nix
                                siteMonitor = local 1337;
                                icon = "mdi-movie-search";
                            })
                        ];
                    }
                    {
                        Homelab = [
                            (tile "Komodo" {
                                href = "https://${config.homelab.komodo.domain}";
                                description = "Deploys";
                                # komodo/core.nix
                                siteMonitor = local 9120;
                                icon = "komodo.svg";
                            })
                            (tile "Beszel" {
                                href = tailnetUrl config.services.beszel.hub.port;
                                description = "Monitoring";
                                siteMonitor = local config.services.beszel.hub.port;
                                icon = "beszel.svg";
                            })
                            (tile "Immich" {
                                href = "https://${config.homelab.immich.domain}";
                                description = "Photos";
                                siteMonitor = local config.services.immich.port;
                                icon = "immich.svg";
                            })
                            (tile "OpenCloud" {
                                href = "https://${config.homelab.drive.domain}";
                                description = "Files";
                                siteMonitor = local config.services.opencloud.port;
                                icon = "open-cloud.svg";
                            })
                            (tile "Pocket ID" {
                                href = "https://${config.homelab.pocketId.domain}";
                                description = "Logins";
                                siteMonitor = local config.services.pocket-id.settings.PORT;
                                icon = "pocket-id.svg";
                            })
                        ];
                    }
                    { Apps = apps; }
                ];
            };

            # Next.js listens on all interfaces unless told otherwise; Caddy is the only way in.
            systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";

            homelab.localNames = lib.genAttrs names (_: cfg.listenPort);
        };
}
