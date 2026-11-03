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
            cfg = config.services.homepage-dashboard;
            beszel = config.services.beszel.hub;

            jellyfinPort = 8096;
            keysDir = "/var/lib/homepage-keys";
            sopsKeys = [
                "komodo-api-key"
                "komodo-api-secret"
                "immich-api-key"
                "tailscale-api-key"
            ];
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

                allowedHosts = lib.concatStringsSep "," (names ++ [ "127.0.0.1:${toString cfg.listenPort}" ]);

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
                                siteMonitor = local jellyfinPort;
                                icon = "jellyfin.svg";
                                widget = {
                                    type = "jellyfin";
                                    url = local jellyfinPort;
                                    key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";

                                    version = 2;
                                    enableBlocks = true;
                                    enableNowPlaying = true;
                                    fields = [
                                        "movies"
                                        "series"
                                        "episodes"
                                    ];
                                };
                            })

                            (tile "AIOStreams" {
                                description = "Streams for Gelato";
                                siteMonitor = config.homelab.media.aiostreams.url;
                                icon = "sh-aiostreams.svg";
                            })
                            (tile "TMDB addon" {
                                description = "Catalogs and search";

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

                                siteMonitor = local 9120;
                                icon = "komodo.svg";
                                widget = {
                                    type = "komodo";
                                    url = local 9120;
                                    key = "{{HOMEPAGE_VAR_KOMODO_KEY}}";
                                    secret = "{{HOMEPAGE_VAR_KOMODO_SECRET}}";
                                    showStacks = true;
                                };
                            })
                            (tile "Beszel" {
                                href = tailnetUrl beszel.port;
                                description = "Monitoring";
                                siteMonitor = local beszel.port;
                                icon = "beszel.svg";
                                widget = {
                                    type = "beszel";
                                    url = local beszel.port;

                                    version = 2;
                                    username = config.homelab.beszel.email;
                                    password = "{{HOMEPAGE_VAR_BESZEL_PASSWORD}}";

                                    systemId = hostName;
                                    fields = [
                                        "status"
                                        "cpu"
                                        "memory"
                                        "disk"
                                    ];
                                };
                            })
                            (tile "Immich" {
                                href = "https://${config.homelab.immich.domain}";
                                description = "Photos";
                                siteMonitor = local config.services.immich.port;
                                icon = "immich.svg";
                                widget = {
                                    type = "immich";
                                    url = local config.services.immich.port;
                                    key = "{{HOMEPAGE_VAR_IMMICH_KEY}}";
                                    version = 2;
                                };
                            })
                            (tile "OpenCloud" {
                                href = "https://${config.homelab.drive.domain}";
                                description = "Files";
                                siteMonitor = local config.services.opencloud.port;
                                icon = "open-cloud.svg";
                            })
                            (tile "Caddy" {
                                description = "Reverse proxy";
                                icon = "caddy.svg";
                                widget = {
                                    type = "caddy";

                                    url = "http://127.0.0.1:2019";
                                };
                            })
                            (tile "Tailscale" {
                                href = "https://login.tailscale.com/admin/machines";
                                description = hostName;
                                icon = "tailscale.svg";
                                widget = {
                                    type = "tailscale";
                                    deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE}}";
                                    key = "{{HOMEPAGE_VAR_TAILSCALE_KEY}}";
                                    fields = [
                                        "address"
                                        "last_seen"
                                        "expires"
                                        "update_available"
                                    ];
                                };
                            })
                            (tile "ntfy" {
                                description = "Alerts";
                                icon = "ntfy.svg";
                                widget = {
                                    type = "ntfy";
                                    url = "{{HOMEPAGE_VAR_NTFY_URL}}";
                                    topic = "{{HOMEPAGE_VAR_NTFY_TOPIC}}";
                                };
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

            services.homepage-dashboard.environmentFiles = [

                "/var/lib/beszel-keys/homepage.env"
                "${keysDir}/keys.env"
                config.sops.templates."homepage.env".path
            ];

            sops.secrets = lib.genAttrs (map (k: "homepage/${k}") sopsKeys) (_: { });
            sops.templates."homepage.env" = {
                content = ''
                    HOMEPAGE_VAR_KOMODO_KEY=${config.sops.placeholder."homepage/komodo-api-key"}
                    HOMEPAGE_VAR_KOMODO_SECRET=${config.sops.placeholder."homepage/komodo-api-secret"}
                    HOMEPAGE_VAR_IMMICH_KEY=${config.sops.placeholder."homepage/immich-api-key"}
                    HOMEPAGE_VAR_TAILSCALE_KEY=${config.sops.placeholder."homepage/tailscale-api-key"}
                '';
                restartUnits = [ "homepage-dashboard.service" ];
            };

            systemd.services.homepage-dashboard = {

                environment.HOSTNAME = "127.0.0.1";
                requires = [ "beszel-keys.service" ];
                after = [
                    "beszel-keys.service"
                    "homepage-keys.service"
                ];
                wants = [ "homepage-keys.service" ];
            };

            systemd.services.homepage-keys = {
                description = "Collect Homepage's widget keys";
                after = [
                    "jellyfin.service"
                    "media-configure.service"
                    "tailscaled.service"
                ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    UMask = "0077";
                    StateDirectory = "homepage-keys";
                };
                path = with pkgs; [
                    curl
                    jq
                    sqlite
                    config.services.tailscale.package
                ];
                script = ''
                    out=${keysDir}/keys.env
                    : > "$out.new"


                    ntfy=$(cat ${config.sops.secrets."ntfy/url".path})
                    printf 'HOMEPAGE_VAR_NTFY_URL=%s\nHOMEPAGE_VAR_NTFY_TOPIC=%s\n' "''${ntfy%/*}" "''${ntfy##*/}" >> "$out.new"


                    device=$(tailscale status --json 2>/dev/null | jq -r '.Self.ID // empty' || true)
                    [ -n "$device" ] && printf 'HOMEPAGE_VAR_TAILSCALE_DEVICE=%s\n' "$device" >> "$out.new"

                    db=${config.services.jellyfin.dataDir}/data/jellyfin.db
                    admin=$(sqlite3 -readonly "$db" "SELECT AccessToken FROM ApiKeys WHERE Name = 'media-configure'" 2>/dev/null || true)
                    if [ -n "$admin" ]; then
                        api() { curl -fsS -H "Authorization: MediaBrowser Token=\"$admin\"" "$@"; }
                        homepage_key() {
                            api ${local jellyfinPort}/Auth/Keys |
                                jq -r '[.Items[] | select(.AppName == "homepage")][0].AccessToken // empty'
                        }
                        key=$(homepage_key || true)
                        if [ -z "$key" ]; then
                            api -X POST "${local jellyfinPort}/Auth/Keys?app=homepage" || true
                            key=$(homepage_key || true)
                        fi
                        [ -n "$key" ] && printf 'HOMEPAGE_VAR_JELLYFIN_KEY=%s\n' "$key" >> "$out.new"
                    fi
                    [ -n "''${key:-}" ] || echo "no Jellyfin key yet (media-configure hasn't run?)" >&2

                    mv "$out.new" "$out"
                '';
            };

            homelab.localNames = lib.genAttrs names (_: cfg.listenPort);
        };
}
