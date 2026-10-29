{ config, ... }:

let
    inherit (config) vars;
in
{
    # media-configure: sets up everything the apps keep in their own databases, which Nix can't
    # write directly: Jellyfin's libraries and users, Decypharr's Real-Debrid key and mount, the
    # AIOStreams user and Gelato's settings, the links between the apps, Prowlarr's indexers, Bazarr's
    # languages and Seerr's defaults. _configure.py talks to each app's API, changes only what differs
    # from the config below, and deletes only what it replaced. It runs at boot and whenever this
    # config changes; a failed step retries.
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
                decypharr
                aiostreams
                gelato
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
                    # The files stream from Real-Debrid (decypharr.nix): reading one whole to make
                    # scrubbing previews or chapter thumbnails would download it.
                    libraryOptions = {
                        EnableTrickplayImageExtraction = false;
                        ExtractTrickplayImagesDuringLibraryScan = false;
                        EnableChapterImageExtraction = false;
                        ExtractChapterImagesDuringLibraryScan = false;
                        # A Gelato stream gets Norwegian (else English) subtitles from OpenSubtitles
                        # through AIOStreams (_aiostreams.json) as soon as it plays. Not always in sync;
                        # the real copy gets synced ones from Bazarr. Kept in Jellyfin's own folder, so
                        # Bazarr doesn't take one for its own and skip the synced download.
                        SubtitleDownloadLanguages = [
                            "nor"
                            "eng"
                        ];
                        SubtitleFetcherOrder = [ "Gelato Subtitles" ];
                        SaveSubtitlesWithMedia = false;
                    };
                    # Screen Grabber would read the whole file for a thumbnail, as above.
                    disabledFetchers = [ "Screen Grabber" ];
                    # Audio in the title's original language, whatever track the release marks as
                    # default. Norwegian subtitles, else English: a comma list is a fallback order, and
                    # any Norwegian tag matches (both through _jellyfin-norwegian.patch). Jellyfin's own
                    # settings page can't show the list, so saving it there drops the fallback until
                    # media-configure runs again. A per-title choice isn't remembered, so a first play
                    # that started without subtitles (they arrive seconds later) doesn't stick at Off.
                    playback = {
                        AudioLanguagePreference = "OriginalLanguage";
                        PlayDefaultAudioTrack = false;
                        SubtitleLanguagePreference = "nor,eng";
                        SubtitleMode = "Always";
                        RememberSubtitleSelections = false;
                    };
                };

                decypharr = {
                    url = url decypharr.port;
                    inherit (decypharr) port;
                    # Decypharr makes its own API token on first start.
                    authFile = "${decypharr.dataDir}/auth.json";
                    realDebridKeyFile = secret "realdebrid-api-key";
                    # Merged into its config.json; _configure.py adds the Real-Debrid key and the arrs.
                    config = {
                        download_folder = decypharr.downloads;
                        categories = [
                            "sonarr"
                            "radarr"
                        ];
                        default_download_action = "symlink";
                        mount = {
                            type = "dfs";
                            mount_path = decypharr.mountPath;
                            dfs = {
                                cache_dir = decypharr.cacheDir;
                                disk_cache_size = "20GB";
                                umask = "022";
                            };
                        };
                    };
                    realDebrid = {
                        provider = "realdebrid";
                        name = "realdebrid";
                        # A release Real-Debrid already has plays at once; any other is fetched by
                        # Real-Debrid first (usually minutes). Cached-only left older films with no
                        # release at all. One that Real-Debrid gives up on fails, and Decypharr's queue
                        # cleanup (on by default) has Sonarr/Radarr blocklist it and take the next.
                        download_uncached = true;
                    };
                };

                # The addon setup Gelato streams from (aiostreams.nix): Real-Debrid releases only,
                # 1080p, original audio and Norwegian subtitles first.
                aiostreams = {
                    inherit (aiostreams) url;
                    configFile = ./_aiostreams.json;
                };

                gelato = {
                    inherit (gelato) pluginId moviePath seriesPath;
                    # AIOStreams' catalogs (by id suffix) that fill the libraries, and how many titles
                    # each brings in per type. Gelato's default is 100, which left a couple hundred
                    # films; clients that search only what they have synced (Infuse) find nothing
                    # else. 10000 is all TMDB lists (500 pages of 20). Trending mostly repeats
                    # Popular, so it stays small.
                    catalogs = {
                        ".tmdb.top" = 10000;
                        ".tmdb.trending" = 100;
                    };
                    # How often they are fetched again. Each run pages through every catalog on the
                    # public TMDB addon, which rate-limits, so not more often than daily.
                    importHours = 24;
                    settings = {
                        # A series' missing seasons and episodes show up next to the ones on disk.
                        ExtendLocalSeriesTrees = true;
                        # Search results stay out of the libraries until someone plays them.
                        HideUnplayedSearchTitles = true;
                        # Sends what we play to a public database.
                        RemuxDbContribute = false;
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
                    # Prowlarr's names (Indexers > Add); the list is the whole set, so one taken out
                    # is removed. Behind Cloudflare: flaresolverr = true. priority 1-50, lower is
                    # preferred when Sonarr and Radarr pick between equal releases; 25 if left out.
                    indexers = {
                        "1337x".flaresolverr = true;
                        "The Pirate Bay".flaresolverr = false;
                        "YTS".flaresolverr = false;
                        "EZTV".flaresolverr = false;
                        "Knaben".flaresolverr = false;
                        "kickasstorrents.to".flaresolverr = false;
                        "LimeTorrents".flaresolverr = false;
                        "Torrent Downloads".flaresolverr = false;
                    };
                };

                bazarr = {
                    url = url config.services.bazarr.settings.general.port;
                    configFile = "${config.services.bazarr.dataDir}/config/config.yaml";
                    profileName = "Norsk";
                    # English too, for when no Norwegian subtitle exists. Norwegian as "no": providers
                    # tag Norwegian subtitles that way, not as Bokmål ("nb"), and Jellyfin's preference
                    # above has to match the file's code.
                    languages = [
                        "no"
                        "en"
                    ];
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
                    # Requests go straight to Sonarr/Radarr without waiting for an admin.
                    autoApprove = true;
                    inherit (config.homelab.media) jellyfinUrl;
                };
            };

            configure = pkgs.writers.writePython3 "media-configure" {
                libraries = with pkgs.python3Packages; [ pyyaml ];
                flakeIgnore = [ "E501" ];
            } (builtins.readFile ./_configure.py);

            apps = [
                "jellyfin.service"
                "decypharr.service"
                "docker-aiostreams.service"
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
