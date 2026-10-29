_:

let
    image = "docker.io/mrcanelas/tmdb-addon:latest@sha256:f05be5ed47e6065806e97d3f43fdf1550b9c00c04ba6e65d36139e037822937c";
    port = 1337;
    url = "http://127.0.0.1:${toString port}";
in
{
    # The TMDB addon AIOStreams' "The Movie Database" preset (_aiostreams.json) gets catalogs, search
    # and metadata from, run here with our own TMDB key. The public instance it uses otherwise
    # (tmdb.elfhosted.com) took 2-14 s per search and rate-limited Gelato's catalog import.
    flake.modules.nixos.media =
        { config, ... }:
        {
            virtualisation.oci-containers.containers = {
                tmdb-addon = {
                    inherit image;
                    environment = {
                        PORT = toString port;
                        HOST_NAME = url;
                        NODE_OPTIONS = "--require /search-filter.js";
                    };
                    # Drops unrated titles and person credits from search results.
                    volumes = [ "${./_tmdb-search-filter.js}:/search-filter.js:ro" ];
                    environmentFiles = [ config.sops.templates."tmdb-addon.env".path ];
                    # Host network, so the NixOS firewall applies; only AIOStreams talks to it.
                    extraOptions = [ "--network=host" ];
                };
                # The preset builds its manifest URL from this instead of the public instance.
                aiostreams.environment.TMDB_ADDON_URL = url;
            };

            sops.secrets."media/tmdb-api-key" = { };
            # The v3 API key (sent as api_key=), not the read access token.
            sops.templates."tmdb-addon.env".content = ''
                TMDB_API=${config.sops.placeholder."media/tmdb-api-key"}
            '';

            # AIOStreams takes a user config only if every addon's manifest answers (configure.nix).
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
