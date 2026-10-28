_:

let
    port = 8282;
in
{
    # Decypharr: Sonarr and Radarr hand it torrents as if it were qBittorrent (arr.nix). It adds them
    # to Real-Debrid and mounts the Real-Debrid library at mountPath, so nothing is downloaded: the
    # arrs import symlinks into that mount and Jellyfin streams from it while you watch. This host
    # never joins a swarm, so there's no VPN. Its settings (Real-Debrid key, mount, arrs, queue
    # cleanup) are set by media-configure through its API (configure.nix).
    flake.modules.nixos.media =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            inherit (config.homelab.media) root;
            cfg = config.homelab.media.decypharr;
        in
        {
            options.homelab.media.decypharr = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = {
                    inherit port;
                    dataDir = "/var/lib/decypharr";
                    cacheDir = "/var/cache/decypharr";
                    # The symlinks in downloads/ and the libraries point here.
                    mountPath = "/mnt/debrid";
                    downloads = "${root}/downloads";
                };
                readOnly = true;
                description = "Decypharr's port and paths, for media-configure (configure.nix).";
            };

            config = {
                users.users.decypharr = {
                    isSystemUser = true;
                    group = "media";
                };

                # Mounting as a normal user goes through the setuid fusermount3; allow_other lets
                # Jellyfin, Sonarr, Radarr and Bazarr read the mount.
                programs.fuse = {
                    enable = true;
                    userAllowOther = true;
                };

                systemd.tmpfiles.settings.decypharr.${cfg.mountPath}.d = {
                    user = "decypharr";
                    group = "media";
                    mode = "0755";
                };

                systemd.services.decypharr = {
                    description = "Decypharr (Real-Debrid client and mount)";
                    wantedBy = [ "multi-user.target" ];
                    after = [ "network-online.target" ];
                    wants = [ "network-online.target" ];
                    # The symlinks go into downloads/ on the media disk.
                    unitConfig.RequiresMountsFor = [ cfg.downloads ];
                    # fusermount3
                    path = [
                        "/run/wrappers"
                        pkgs.jq
                    ];
                    # Token-only login: the API token (auth.json, made on first start) is the only
                    # credential, for media-configure and for the web UI. Otherwise the first visitor
                    # would pick the password. DECYPHARR_AUTH_TOKEN_ONLY is lost in 2.7.1, so it is
                    # set in the file.
                    preStart = ''
                        # A crash leaves the mount behind as "transport endpoint is not connected".
                        fusermount3 -uz ${cfg.mountPath} || true

                        auth=${cfg.dataDir}/auth.json
                        if [ -e "$auth" ]; then
                            jq '.token_only = true' "$auth" > "$auth.tmp" && mv "$auth.tmp" "$auth"
                        else
                            echo '{"token_only":true}' > "$auth"
                        fi
                        chmod 600 "$auth"
                    '';
                    serviceConfig = {
                        User = "decypharr";
                        Group = "media";
                        UMask = "0002";
                        ExecStart = "${lib.getExe pkgs.decypharr} --config ${cfg.dataDir}";
                        StateDirectory = "decypharr";
                        StateDirectoryMode = "0750";
                        CacheDirectory = "decypharr";
                        Restart = "on-failure";
                        RestartSec = 10;
                    };
                };

                # Web UI; Sonarr and Radarr reach it on localhost.
                networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
                # https://<host>.<tailnet>.ts.net:8282 (tailscale-https.nix).
                homelab.tailscaleHttps = [ port ];

                # Settings, login and the torrent list; the media itself lives on Real-Debrid.
                homelab.backup.paths = [ cfg.dataDir ];
            };
        };
}
