{ config, ... }:

let
    inherit (config) vars;
in
{

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

                    libraryOptions = {
                        EnableTrickplayImageExtraction = false;
                        ExtractTrickplayImagesDuringLibraryScan = false;
                        EnableChapterImageExtraction = false;
                        ExtractChapterImagesDuringLibraryScan = false;

                        SubtitleDownloadLanguages = [
                            "nor"
                            "eng"
                        ];
                        SubtitleFetcherOrder = [ "Gelato Subtitles" ];
                        SaveSubtitlesWithMedia = false;
                    };

                    disabledFetchers = [
                        "Screen Grabber"
                        "The Open Movie Database"
                    ];

                    playback = {
                        AudioLanguagePreference = "OriginalLanguage";
                        PlayDefaultAudioTrack = false;
                        SubtitleLanguagePreference = "nor,eng";
                        SubtitleMode = "Always";
                        RememberSubtitleSelections = false;
                    };
                };

                aiostreams = {
                    inherit (aiostreams) url;
                    configFile = ./_aiostreams.json;
                };

                gelato = {
                    inherit (gelato) pluginId moviePath seriesPath;

                    catalogs = {
                        ".tmdb.top" = 500;
                        ".tmdb.trending" = 100;
                    };

                    importHours = 24;
                    settings = {

                        ExtendLocalSeriesTrees = true;

                        HideUnplayedSearchTitles = true;

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
                    [ "realdebrid-api-key" ] ++ map (u: "jellyfin-password/${u.name}") users
                )) (_: { });

                systemd.services.media-configure = {
                    description = "Configure the media apps through their APIs";
                    wantedBy = [ "multi-user.target" ];
                    wants = apps;
                    after = apps;
                    path = [ config.systemd.package ];

                    serviceConfig = {
                        Type = "exec";
                        ExecStart = "${configure} ${pkgs.writeText "media-configure.json" (builtins.toJSON settings)}";
                        StateDirectory = "media-configure";
                        StateDirectoryMode = "0700";

                        Restart = "on-failure";
                        RestartSec = "2min";
                    };
                    startLimitBurst = 5;
                    startLimitIntervalSec = 3600;
                };
            };
        };
}
