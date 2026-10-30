{ config, ... }:

let
    inherit (config) vars;
in
{
    # media-configure: sets up everything the apps keep in their own databases, which Nix can't
    # write directly: Jellyfin's libraries and users, the AIOStreams user and Gelato's settings.
    # _configure.py talks to each app's API, changes only what differs from the config below, and
    # deletes only what it replaced. It runs at boot and whenever this config changes; a failed step
    # retries.
    flake.modules.nixos.homelab =
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
                aiostreams
                gelato
                ;
            secret = name: config.sops.secrets."media/${name}".path;
            url = port: "http://127.0.0.1:${toString port}";
            jellyfinPort = 8096;

            # The first user is the admin.
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
                    # Gelato's titles stream from Real-Debrid: reading one whole to make scrubbing
                    # previews or chapter thumbnails would download it.
                    libraryOptions = {
                        EnableTrickplayImageExtraction = false;
                        ExtractTrickplayImagesDuringLibraryScan = false;
                        EnableChapterImageExtraction = false;
                        ExtractChapterImagesDuringLibraryScan = false;
                        # A Gelato stream gets Norwegian (else English) subtitles from OpenSubtitles
                        # through AIOStreams (_aiostreams.json) as soon as it plays. Not always in sync.
                        SubtitleDownloadLanguages = [
                            "nor"
                            "eng"
                        ];
                        SubtitleFetcherOrder = [ "Gelato Subtitles" ];
                        SaveSubtitlesWithMedia = false;
                    };
                    # Screen Grabber reads the whole file for thumbnails; OMDb has dead Amazon image URLs and broken JSON.
                    disabledFetchers = [
                        "Screen Grabber"
                        "The Open Movie Database"
                    ];
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

                # The addon setup Gelato streams from (aiostreams.nix): Real-Debrid releases only,
                # 1080p, original audio and Norwegian subtitles first.
                aiostreams = {
                    inherit (aiostreams) url;
                    configFile = ./_aiostreams.json;
                };

                gelato = {
                    inherit (gelato) pluginId moviePath seriesPath;
                    # AIOStreams' catalogs (by id suffix) that fill the libraries, and how many titles
                    # each brings in per type: what browsing shows. Search finds anything else
                    # through the addon. Trending mostly repeats Popular, so it stays small.
                    catalogs = {
                        ".tmdb.top" = 500;
                        ".tmdb.trending" = 100;
                    };
                    # How often they are fetched again. Each run pages through every catalog, about
                    # 1000 requests to TMDB, so not more often than daily.
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
            };

            configure = pkgs.writers.writePython3 "media-configure" {
                flakeIgnore = [ "E501" ];
            } (builtins.readFile ./_configure.py);

            apps = [
                "jellyfin.service"
                "docker-aiostreams.service"
            ];
        in
        {
            options.homelab.media.keysDir = lib.mkOption {
                type = lib.types.str;
                default = "/var/lib/media-configure";
                readOnly = true;
                description = "media-configure's state: the AIOStreams user it made.";
            };

            config = {
                sops.secrets = lib.genAttrs (map (n: "media/${n}") (
                    [ "realdebrid-api-key" ]
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
                        # Apps still starting: try again a few times.
                        Restart = "on-failure";
                        RestartSec = "2min";
                    };
                    startLimitBurst = 5;
                    startLimitIntervalSec = 3600;
                };
            };
        };
}
