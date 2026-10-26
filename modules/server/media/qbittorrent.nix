_:

let
    gluetunImage = "qmcgaw/gluetun:v3.41.3";
    qbittorrentImage = "lscr.io/linuxserver/qbittorrent:5.3.0";
    # qBittorrent's web UI inside the VPN namespace, published on localhost for Sonarr and Radarr.
    localPort = 8081;
    # The same UI for the tailnet (qbittorrent-ui below).
    uiPort = 8080;
    uid = 2000;
in
{
    # qBittorrent inside Gluetun's network namespace: Gluetun holds the VPN tunnel and firewalls
    # everything else, so if the tunnel drops, torrent traffic stops instead of leaking out the
    # home IP. Sonarr and Radarr (arr.nix) add torrents through it.
    flake.modules.nixos.media =
        { config, ... }:
        let
            inherit (config.homelab.media) root;
            downloads = "${root}/downloads";
            dataDir = "/var/lib/qbittorrent";
        in
        {
            # The provider's settings as a dotenv block (https://github.com/qdm12/gluetun-wiki):
            #   gluetun/env: |
            #     VPN_SERVICE_PROVIDER=mullvad
            #     VPN_TYPE=wireguard
            #     WIREGUARD_PRIVATE_KEY=...
            #     WIREGUARD_ADDRESSES=10.x.x.x/32
            #     SERVER_COUNTRIES=Sweden
            sops.secrets."gluetun/env" = { };

            # The container gets these as numbers (PUID/PGID), so both are fixed.
            users.users.qbittorrent = {
                inherit uid;
                isSystemUser = true;
                group = "media";
            };

            virtualisation.docker.enable = true;
            virtualisation.oci-containers = {
                backend = "docker";

                containers.gluetun = {
                    image = gluetunImage;
                    # Localhost only: Docker bypasses the firewall.
                    ports = [ "127.0.0.1:${toString localPort}:${toString uiPort}" ];
                    environment.TZ = config.time.timeZone;
                    environmentFiles = [ config.sops.secrets."gluetun/env".path ];
                    extraOptions = [
                        "--cap-add=NET_ADMIN"
                        "--device=/dev/net/tun"
                    ];
                };

                containers.qbittorrent = {
                    image = qbittorrentImage;
                    dependsOn = [ "gluetun" ];
                    environment = {
                        PUID = toString uid;
                        PGID = toString config.users.groups.media.gid;
                        UMASK = "002";
                        WEBUI_PORT = toString uiPort;
                        TZ = config.time.timeZone;
                    };
                    volumes = [
                        "${dataDir}:/config"
                        # Same path inside and out, so the paths qBittorrent reports to Sonarr and
                        # Radarr exist on the host too and they can hardlink them.
                        "${downloads}:${downloads}"
                    ];
                    extraOptions = [ "--network=container:gluetun" ];
                };
            };

            systemd.tmpfiles.settings.qbittorrent.${dataDir}.d = {
                user = "qbittorrent";
                group = "media";
                mode = "0750";
            };

            systemd.services = {
                # A restarted Gluetun is a new network namespace, and qBittorrent's goes with the old
                # one. BindsTo stops qBittorrent with it; Upholds starts it again once Gluetun is back.
                docker-gluetun.unitConfig.Upholds = [ "docker-qbittorrent.service" ];
                docker-qbittorrent = {
                    bindsTo = [ "docker-gluetun.service" ];
                    unitConfig.RequiresMountsFor = [ downloads ];
                };

                # The published port is localhost only, so this relays it to the tailnet. It runs on
                # the host, where the NixOS firewall applies (opened on tailscale0 only).
                qbittorrent-ui = {
                    requires = [ "qbittorrent-ui.socket" ];
                    after = [ "qbittorrent-ui.socket" ];
                    serviceConfig = {
                        ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString localPort}";
                        DynamicUser = true;
                        PrivateTmp = true;
                    };
                };
            };
            systemd.sockets.qbittorrent-ui = {
                wantedBy = [ "sockets.target" ];
                listenStreams = [ (toString uiPort) ];
            };
            networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ uiPort ];

            # Settings, categories and the torrent list; the downloads themselves are not copied.
            homelab.backup.paths = [ dataDir ];
        };
}
