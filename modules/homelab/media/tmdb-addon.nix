_:

let
    image = "docker.io/mrcanelas/tmdb-addon:latest@sha256:f05be5ed47e6065806e97d3f43fdf1550b9c00c04ba6e65d36139e037822937c";
    port = 1337;
    url = "http://127.0.0.1:${toString port}";
in
{

    flake.modules.nixos.homelab =
        { config, ... }:
        {
            virtualisation.oci-containers.containers = {
                tmdb-addon = {
                    inherit image;
                    environment = {
                        PORT = toString port;
                        HOST_NAME = url;
                        NODE_OPTIONS = "--require /search-filter.js";

                        FANART_API = "none";
                    };

                    volumes = [ "${./_tmdb-search-filter.js}:/search-filter.js:ro" ];
                    environmentFiles = [ config.sops.templates."tmdb-addon.env".path ];

                    extraOptions = [ "--network=host" ];
                };

                aiostreams.environment.TMDB_ADDON_URL = url;
            };

            sops.secrets."media/tmdb-api-key" = { };

            sops.templates."tmdb-addon.env".content = ''
                TMDB_API=${config.sops.placeholder."media/tmdb-api-key"}
            '';

            systemd.services.docker-aiostreams = {
                wants = [ "docker-tmdb-addon.service" ];
                after = [ "docker-tmdb-addon.service" ];
            };
            systemd.services.media-configure = {
                wants = [ "docker-tmdb-addon.service" ];
                after = [ "docker-tmdb-addon.service" ];
            };
        };
}
