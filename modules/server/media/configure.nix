{ config, ... }:

let
    inherit (config) vars;
in
{
    # media-configure: sets up everything the apps keep in their own databases, which Nix can't
    # write directly: Jellyfin's libraries and users, rdt-client's Real-Debrid key, the links between
    # the apps, Prowlarr's indexers, Bazarr's languages and Seerr's defaults. _configure.py talks to
    # each app's API, changes only what differs from the config below, and never deletes. It runs at
    # boot and whenever this config changes; a failed step retries.
    flake.modules.nixos.media =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            inherit (config.homelab.media)
                root
                keysDir
                profiles
                rdtclientPort
                ;
            secret = name: config.sops.secrets."media/${name}".path;
            port = app: config.services.${app}.settings.server.port;
            url = port: "http://127.0.0.1:${toString port}";
            jellyfinPort = 8096;

            # The first user is the admin and Seerr's owner.
            users = [
                {
                    name = vars.user.name;
                    admin = true;
                }
                {
                    name = "sofie";
                    admin = false;
                }
            ];

            settings = {
                inherit keysDir;
                # Nordic releases usually have Norwegian subtitles in the file.
                customFormats = [
                    {
                        name = "NORDiC";
                        regex = "\\bNORDIC\\b";
                        score = 100;
                    }
                ];

                jellyfin = {
                    url = url jellyfinPort;
                    port = jellyfinPort;
                    db = "${config.services.jellyfin.dataDir}/data/jellyfin.db";
                    serverName = "Snyltflix";
                    country = "NO";
                    metadataLanguage = "en";
                    libraries = [
                        {
                            name = "Filmer";
                            type = "movies";
                            path = "${root}/media/movies";
                        }
                        {
                            name = "Serier";
                            type = "tvshows";
                            path = "${root}/media/shows";
                        }
                    ];
                    users = map (u: u // { passwordFile = secret "jellyfin-password/${u.name}"; }) users;
                    # Original audio (the file's default track) with Norwegian subtitles from Bazarr.
                    playback = {
                        SubtitleLanguagePreference = "nob";
                        SubtitleMode = "Always";
                        PlayDefaultAudioTrack = true;
                    };
                };

                rdtclient = {
                    url = url rdtclientPort;
                    port = rdtclientPort;
                    user = vars.user.name;
                    passwordFile = secret "rdtclient-password";
                    realDebridKeyFile = secret "realdebrid-api-key";
                    # Real-Debrid (0) with the built-in downloader (0), into the shared downloads/
                    # under the same path as on the host (rdt-client.nix).
                    settings = {
                        "Provider:Provider" = 0;
                        "DownloadClient:Client" = 0;
                        "DownloadClient:DownloadPath" = "${root}/downloads";
                        "DownloadClient:MappedPath" = "${root}/downloads";
                    };
                };

                sonarr = {
                    url = url (port "sonarr");
                    port = port "sonarr";
                    configFile = "${config.services.sonarr.dataDir}/config.xml";
                    rootFolder = "${root}/media/shows";
                    categoryField = "tvCategory";
                    profile = profiles.sonarr;
                };
                radarr = {
                    url = url (port "radarr");
                    port = port "radarr";
                    configFile = "${config.services.radarr.dataDir}/config.xml";
                    rootFolder = "${root}/media/movies";
                    categoryField = "movieCategory";
                    profile = profiles.radarr;
                };

                prowlarr = {
                    url = url (port "prowlarr");
                    configFile = "/var/lib/private/prowlarr/config.xml";
                    flaresolverr = "http://127.0.0.1:${toString config.services.flaresolverr.port}/";
                    # Prowlarr's names (Indexers > Add). Behind Cloudflare: flaresolverr = true.
                    indexers = {
                        "1337x".flaresolverr = true;
                        "The Pirate Bay".flaresolverr = false;
                        "YTS".flaresolverr = false;
                        "EZTV".flaresolverr = false;
                        "Knaben".flaresolverr = false;
                    };
                };

                bazarr = {
                    url = url config.services.bazarr.settings.general.port;
                    configFile = "${config.services.bazarr.dataDir}/config/config.yaml";
                    profileName = "Norsk";
                    languages = [ "nb" ];
                    # OpenSubtitles has the most Norwegian subtitles; embedded ones are already in
                    # the file.
                    providers = [
                        "opensubtitlescom"
                        "embeddedsubtitles"
                        "podnapisi"
                    ];
                    secretFiles = {
                        settings-opensubtitlescom-username = secret "opensubtitles-username";
                        settings-opensubtitlescom-password = secret "opensubtitles-password";
                    };
                };

                seerr = {
                    url = url config.services.seerr.port;
                    inherit (config.services.seerr) configDir;
                    # Seerr wants an email for its owner; it is never mailed.
                    emailDomain = "snyltflix.local";
                    inherit (config.homelab.media) jellyfinUrl;
                };
            };

            configure = pkgs.writers.writePython3 "media-configure" {
                libraries = with pkgs.python3Packages; [ pyyaml ];
                flakeIgnore = [ "E501" ];
            } (builtins.readFile ./_configure.py);

            apps = [
                "jellyfin.service"
                "docker-rdtclient.service"
                "sonarr.service"
                "radarr.service"
                "prowlarr.service"
                "flaresolverr.service"
                "bazarr.service"
                "seerr.service"
            ];
        in
        {
            options.homelab.media.keysDir = lib.mkOption {
                type = lib.types.str;
                default = "/var/lib/media-configure";
                readOnly = true;
                description = "Where media-configure leaves the Sonarr and Radarr API keys for Recyclarr.";
            };

            config = {
                sops.secrets = lib.genAttrs (map (n: "media/${n}") (
                    [
                        "rdtclient-password"
                        "realdebrid-api-key"
                        "opensubtitles-username"
                        "opensubtitles-password"
                    ]
                    ++ map (u: "jellyfin-password/${u.name}") users
                )) (_: { });

                systemd.services.media-configure = {
                    description = "Configure the media apps through their APIs";
                    wantedBy = [ "multi-user.target" ];
                    wants = apps;
                    after = apps;
                    path = [ config.systemd.package ];
                    # Restarts whenever the script or settings change, as both are in ExecStart.
                    serviceConfig = {
                        Type = "exec";
                        ExecStart = "${configure} ${pkgs.writeText "media-configure.json" (builtins.toJSON settings)}";
                        StateDirectory = "media-configure";
                        StateDirectoryMode = "0700";
                        # Apps still starting, or an indexer down: try again a few times.
                        Restart = "on-failure";
                        RestartSec = "2min";
                    };
                    startLimitBurst = 5;
                    startLimitIntervalSec = 3600;
                };
            };
        };
}
