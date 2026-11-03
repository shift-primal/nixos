_:

{

    flake.modules.nixos.homelab =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            cfg = config.services.immich;
            postgres = config.services.postgresql.package;
        in
        {
            options.homelab.immich.domain = lib.mkOption {
                type = lib.types.str;
                description = "Public domain Caddy serves Immich on, through the tunnel (cloudflared.nix).";
                example = "photos.example.com";
            };

            config.services.immich = {
                enable = true;

                host = "";
                openFirewall = true;

                settings = {

                    storageTemplate = {
                        enabled = true;
                        template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
                    };

                    backup.database.enabled = false;

                    server.externalDomain = "https://${config.homelab.immich.domain}";
                };
            };

            config.services.caddy.virtualHosts."http://${config.homelab.immich.domain}".extraConfig = ''
                reverse_proxy 127.0.0.1:${toString cfg.port}
            '';

            config.systemd.tmpfiles.settings.immich.${cfg.mediaLocation} = lib.mkForce {
                d = {
                    inherit (cfg) user group;
                    mode = "0700";
                };
            };
            config.systemd.services.immich-server.unitConfig.RequiresMountsFor = [ cfg.mediaLocation ];

            config.services.immich.machine-learning.environment.IMMICH_PORT = lib.mkForce "2284";
            config.services.immich.environment.IMMICH_MACHINE_LEARNING_URL =
                lib.mkForce "http://localhost:2284";

            config.systemd.services.immich-machine-learning.serviceConfig = {
                MemoryHigh = "3G";
                MemoryMax = "4G";
            };
            config.systemd.slices.system-immich.sliceConfig.CPUWeight = 50;

            config.homelab.backup = {
                paths = [ cfg.mediaLocation ];
                exclude = map (dir: "${cfg.mediaLocation}/${dir}") [
                    "thumbs"
                    "encoded-video"
                    "backups"
                ];

                dumps."immich.sql.gz" = ''
                    ${pkgs.util-linux}/bin/runuser -u postgres -- ${postgres}/bin/pg_dump --clean --if-exists ${cfg.database.name} |
                        ${lib.getExe pkgs.gzip}
                '';
            };
        };
}
