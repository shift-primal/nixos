_:

let
    image = "docker.io/viren070/aiostreams:v2.37.0";
    port = 3000;
    dataDir = "/var/lib/aiostreams";
in
{
    # AIOStreams: one Stremio addon that asks several torrent indexers (Comet, StremThru) which
    # releases Real-Debrid has, and sorts them by our preferences. MediaFusion is off in
    # _aiostreams.json: ElfHosted's public instance lists streams that then 404 on play. Gelato (gelato.nix) asks it
    # for a catalog, a search or the stream for a title; nobody opens its own UI. Its user config
    # (_aiostreams.json) is set by media-configure (configure.nix).
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
                            # Its per-IP limits are for public instances. Here every request comes from
                            # Jellyfin on 127.0.0.1, and Gelato's catalog import asks for hundreds of
                            # titles at once: about half of them got "Rate Limit Exceeded" and were skipped.
                            DISABLE_RATE_LIMITS = "true";
                        };
                        environmentFiles = [
                            config.sops.templates."aiostreams.env".path
                            "${dataDir}/secret.env"
                        ];
                        # Host network, so the NixOS firewall applies (a published port would bypass
                        # it) and nothing opens the port: only Jellyfin, on this host, talks to it.
                        extraOptions = [ "--network=host" ];
                    };
                };

                # The Real-Debrid key, so the user config never holds it.
                sops.templates."aiostreams.env".content = ''
                    FORCED_SERVICE_CREDENTIALS=realdebrid.apiKey=${config.sops.placeholder."media/realdebrid-api-key"}
                '';

                # The key AIOStreams encrypts its configs with. Made here once rather than kept in
                # sops: if it is lost, media-configure makes a new user config with it.
                systemd.services.docker-aiostreams.preStart = lib.mkBefore ''
                    mkdir -p ${dataDir}
                    if [ ! -s ${dataDir}/secret.env ]; then
                        (umask 077; echo "SECRET_KEY=$(${config.systemd.package}/bin/systemd-id128 new)$(${config.systemd.package}/bin/systemd-id128 new)" > ${dataDir}/secret.env)
                    fi
                '';

                # Its database; the user config can be made again, but this keeps the URL Gelato has.
                homelab.backup.paths = [ dataDir ];
            };
        };
}
