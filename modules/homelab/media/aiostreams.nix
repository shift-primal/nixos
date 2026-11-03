_:

let
    image = "docker.io/viren070/aiostreams:v2.37.0";
    port = 3000;
    dataDir = "/var/lib/aiostreams";
in
{

    flake.modules.nixos.homelab =
        { config, lib, ... }:
        {
            options.homelab.media.aiostreams = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = {
                    url = "http://127.0.0.1:${toString port}";
                    inherit dataDir;
                };
                readOnly = true;
                description = "AIOStreams' address and data folder, for media-configure (configure.nix).";
            };

            config = {
                virtualisation.oci-containers = {
                    backend = "docker";
                    containers.aiostreams = {
                        inherit image;
                        volumes = [ "${dataDir}:/app/data" ];
                        environment = {
                            BASE_URL = "http://127.0.0.1:${toString port}";
                            PORT = toString port;
                            TZ = config.time.timeZone;

                            DISABLE_RATE_LIMITS = "true";
                        };
                        environmentFiles = [
                            config.sops.templates."aiostreams.env".path
                            "${dataDir}/secret.env"
                        ];

                        extraOptions = [ "--network=host" ];
                    };
                };

                sops.templates."aiostreams.env".content = ''
                    FORCED_SERVICE_CREDENTIALS=realdebrid.apiKey=${config.sops.placeholder."media/realdebrid-api-key"}
                '';

                systemd.services.docker-aiostreams.preStart = lib.mkBefore ''
                    mkdir -p ${dataDir}
                    if [ ! -s ${dataDir}/secret.env ]; then
                        (umask 077; echo "SECRET_KEY=$(${config.systemd.package}/bin/systemd-id128 new)$(${config.systemd.package}/bin/systemd-id128 new)" > ${dataDir}/secret.env)
                    fi
                '';

                homelab.backup.paths = [ dataDir ];
            };
        };
}
