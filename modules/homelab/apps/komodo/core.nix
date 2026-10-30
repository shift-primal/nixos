_:

let
    # Matches the komodo package in nixpkgs, which runs Periphery (periphery.nix).
    # Bump both together: Core and Periphery speak a versioned protocol.
    coreImage = "ghcr.io/moghtech/komodo-core:2.3.3";
    mongoImage = "mongo:8.0";
    network = "komodo";
    dataDir = "/var/lib/komodo-core";
in
{
    # Komodo Core and its MongoDB. nixpkgs has no Core module and does not build its web UI,
    # so Core runs from the upstream image, laid out like upstream's mongo.compose.yaml.
    flake.modules.nixos.homelab =
        { config, lib, ... }:
        let
            cfg = config.homelab.komodo;
            hostname = config.networking.hostName;
            inherit (config.sops) placeholder;
        in
        {
            options.homelab.komodo.domain = lib.mkOption {
                type = lib.types.str;
                description = "Domain Caddy serves the Komodo UI on.";
                example = "komodo.example.com";
            };

            options.homelab.komodo.webhookDomain = lib.mkOption {
                type = lib.types.str;
                description = ''
                    Domain that lets git webhooks reach Core; it serves only /listener/*, so the hooks
                    already set in GitHub keep working whatever guards the UI domain. Komodo checks each
                    call against komodo/webhook-secret.
                '';
                example = "hooks.example.com";
            };

            config = {
                virtualisation.oci-containers = {
                    backend = "docker";

                    containers.komodo-mongo = {
                        image = mongoImage;
                        cmd = [
                            "--quiet"
                            "--wiredTigerCacheSizeGB"
                            "0.25"
                        ];
                        volumes = [
                            "${dataDir}/mongo/db:/data/db"
                            "${dataDir}/mongo/config:/data/configdb"
                        ];
                        environmentFiles = [ config.sops.templates."komodo-mongo.env".path ];
                        # Keeps Komodo's "stop all containers" away from its own database.
                        labels."komodo.skip" = "";
                        networks = [ network ];
                    };

                    containers.komodo-core = {
                        image = coreImage;
                        dependsOn = [ "komodo-mongo" ];
                        # Localhost only: Caddy (caddy.nix) is the way in, and Periphery dials it here.
                        ports = [ "127.0.0.1:9120:9120" ];
                        volumes = [
                            "${dataDir}/keys:/config/keys"
                            "${dataDir}/backups:/backups"
                            # Periphery writes its public key here on first start (periphery.nix).
                            "${config.services.komodo-periphery.rootDirectory}/keys:/periphery-keys:ro"
                        ];
                        environment = {
                            KOMODO_HOST = "https://${cfg.domain}";
                            # The webhook URLs the UI shows point here.
                            KOMODO_WEBHOOK_BASE_URL = "https://${cfg.webhookDomain}";
                            KOMODO_DATABASE_ADDRESS = "komodo-mongo:27017";
                            # No Cloudflare Access in front: this login is the only guard on the public
                            # UI, so nobody can sign up and the admin is the one account.
                            KOMODO_LOCAL_AUTH = "true";
                            KOMODO_INIT_ADMIN_USERNAME = "admin";
                            KOMODO_DISABLE_USER_REGISTRATION = "true";
                            # Single admin; the type-the-name confirm on every deploy is just friction.
                            KOMODO_DISABLE_CONFIRM_DIALOG = "true";
                            KOMODO_FIRST_SERVER_NAME = hostname;
                            KOMODO_PERIPHERY_PUBLIC_KEY = "file:/periphery-keys/periphery.pub";
                            TZ = config.time.timeZone;
                        };
                        environmentFiles = [ config.sops.templates."komodo-core.env".path ];
                        extraOptions = [ "--init" ];
                        networks = [ network ];
                    };
                };

                # Containers resolve each other by name only on a user-defined network.
                systemd.services.docker-network-komodo = {
                    description = "Docker network for Komodo";
                    after = [ "docker.service" ];
                    requires = [ "docker.service" ];
                    before = [
                        "docker-komodo-mongo.service"
                        "docker-komodo-core.service"
                    ];
                    requiredBy = [
                        "docker-komodo-mongo.service"
                        "docker-komodo-core.service"
                    ];
                    serviceConfig = {
                        Type = "oneshot";
                        RemainAfterExit = true;
                    };
                    path = [ config.virtualisation.docker.package ];
                    script = "docker network inspect ${network} >/dev/null 2>&1 || docker network create ${network}";
                };

                systemd.tmpfiles.settings."10-komodo-core" =
                    lib.genAttrs
                        [
                            dataDir
                            "${dataDir}/backups"
                            "${dataDir}/mongo/db"
                            "${dataDir}/mongo/config"
                        ]
                        (_: {
                            d.mode = "0700";
                        })
                    // {
                        # Periphery reads core.pub from here (periphery.nix), nobody else gets in.
                        "${dataDir}".d.mode = "0755";
                        "${dataDir}/keys".d = {
                            mode = "0750";
                            group = config.services.komodo-periphery.group;
                        };
                    };

                # Values go in secrets/hosts/<hostname>.yaml (sops), e.g. from `openssl rand -hex 32`:
                # base64 can put `+/=` into the MongoDB connection string.
                # The host fails to build until that file exists.
                sops.secrets = {
                    "komodo/db-password" = { };
                    "komodo/jwt-secret" = { };
                    "komodo/webhook-secret" = { };
                    # Only read on Core's first start, to create the admin user.
                    "komodo/admin-password" = { };
                };

                sops.templates."komodo-mongo.env" = {
                    content = ''
                        MONGO_INITDB_ROOT_USERNAME=komodo
                        MONGO_INITDB_ROOT_PASSWORD=${placeholder."komodo/db-password"}
                    '';
                    restartUnits = [ "docker-komodo-mongo.service" ];
                };

                sops.templates."komodo-core.env" = {
                    content = ''
                        KOMODO_DATABASE_USERNAME=komodo
                        KOMODO_DATABASE_PASSWORD=${placeholder."komodo/db-password"}
                        KOMODO_JWT_SECRET=${placeholder."komodo/jwt-secret"}
                        KOMODO_WEBHOOK_SECRET=${placeholder."komodo/webhook-secret"}
                        KOMODO_INIT_ADMIN_PASSWORD=${placeholder."komodo/admin-password"}
                    '';
                    restartUnits = [ "docker-komodo-core.service" ];
                };

                # Mongo's files are dumped instead of copied live (backup.nix).
                homelab.backup = {
                    paths = [ dataDir ];
                    exclude = [ "${dataDir}/mongo" ];
                    dumps."komodo-mongo.archive.gz" = ''
                        ${config.virtualisation.docker.package}/bin/docker exec komodo-mongo sh -c 'exec mongodump --quiet --archive --gzip --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin'
                    '';
                };

                services.caddy.virtualHosts = {
                    "http://${cfg.domain}".extraConfig = ''
                        reverse_proxy 127.0.0.1:9120
                    '';
                    "http://${cfg.webhookDomain}".extraConfig = ''
                        handle /listener/* {
                            reverse_proxy 127.0.0.1:9120
                        }
                        respond 404
                    '';
                };
            };
        };
}
