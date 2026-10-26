_:

let
    image = "rogerfar/rdtclient:2.0.143";
    port = 6500;
    uid = 2000;
in
{
    # rdt-client: Sonarr and Radarr hand it torrents as if it were qBittorrent (arr.nix), it has
    # Real-Debrid fetch them, then downloads the result over HTTPS. This host never joins a swarm,
    # so there's no VPN. Its login and Real-Debrid key are set by media-configure (configure.nix).
    flake.modules.nixos.media =
        { config, lib, ... }:
        let
            downloads = "${config.homelab.media.root}/downloads";
            dataDir = "/var/lib/rdtclient";
        in
        {
            options.homelab.media.rdtclientPort = lib.mkOption {
                type = lib.types.port;
                default = port;
                readOnly = true;
                description = "rdt-client's web UI and qBittorrent API port.";
            };

            config = {
                # The container gets these as numbers (PUID/PGID), so both are fixed.
                users.users.rdtclient = {
                    inherit uid;
                    isSystemUser = true;
                    group = "media";
                };

                virtualisation.docker.enable = true;
                virtualisation.oci-containers = {
                    backend = "docker";
                    containers.rdtclient = {
                        inherit image;
                        environment = {
                            PUID = toString uid;
                            PGID = toString config.users.groups.media.gid;
                            UMASK = "002";
                            TZ = config.time.timeZone;
                        };
                        volumes = [
                            "${dataDir}:/data/db"
                            # Same path inside and out, so the paths it reports to Sonarr and Radarr exist
                            # on the host too and they can hardlink them.
                            "${downloads}:${downloads}"
                        ];
                        # Host network, so it listens like a host service and the NixOS firewall applies
                        # (a published port would bypass it). Sonarr and Radarr reach it on localhost.
                        extraOptions = [ "--network=host" ];
                    };
                };
                networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

                systemd.tmpfiles.settings.rdtclient.${dataDir}.d = {
                    user = "rdtclient";
                    group = "media";
                    mode = "0750";
                };
                systemd.services.docker-rdtclient.unitConfig.RequiresMountsFor = [ downloads ];

                # Settings, the API key and the download list; the downloads themselves are not copied.
                homelab.backup.paths = [ dataDir ];
            };
        };
}
