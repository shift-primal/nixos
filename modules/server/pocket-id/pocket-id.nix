_:

{
    # Pocket ID: one login for the homelab's web apps, with passkeys instead of passwords. Public
    # through the tunnel, since phones and the desktop sync apps sign in from anywhere. Users, groups
    # and the apps (OIDC clients) are declared below and in each app's file (opencloud.nix), and
    # pocket-id-provision (_provision.py) writes them in through Pocket ID's API.
    flake.modules.nixos.pocket-id =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            cfg = config.homelab.pocketId;
            inherit (config.services.pocket-id) dataDir;
            port = 1411;
            # Made on the box on first start, so the repo holds no secret and a new install needs no
            # sops step. The nightly backup keeps a copy: without encryption-key a restored database
            # is unreadable.
            keysDir = "/var/lib/pocket-id-keys";
            db = "${dataDir}/data/pocket-id.db";
            env = (pkgs.formats.keyValue { }).generate "pocket-id.env" config.services.pocket-id.settings;
            inherit (lib) mkOption types;

            # `sudo pocket-id-login <user>` prints a link that signs in once, valid an hour. That is how
            # a new user gets in to add their first passkey, and the way back in after losing one.
            login = pkgs.writeShellScriptBin "pocket-id-login" ''
                set -euo pipefail
                set -a
                . ${env}
                ENCRYPTION_KEY=$(cat ${keysDir}/encryption-key)
                set +a
                cd ${dataDir}
                exec ${pkgs.util-linux}/bin/runuser -u pocket-id -- \
                    ${lib.getExe config.services.pocket-id.package} one-time-access-token "$1"
            '';

            provision = pkgs.writers.writePython3 "pocket-id-provision" {
                flakeIgnore = [ "E501" ];
            } (builtins.readFile ./_provision.py);
            settings = {
                url = "http://127.0.0.1:${toString port}";
                apiKeyFile = "${keysDir}/api-key";
                inherit (cfg) users groups clients;
            };
        in
        {
            options.homelab.pocketId = {
                domain = mkOption {
                    type = types.str;
                    description = "Domain Pocket ID is served on. Every app's login goes through it.";
                    example = "id.example.com";
                };
                users = mkOption {
                    description = "Accounts, by username. Admins manage Pocket ID itself.";
                    type = types.attrsOf (
                        types.submodule {
                            options = {
                                fullName = mkOption {
                                    type = types.str;
                                    description = "Split at the first space into first and last name.";
                                };
                                admin = mkOption {
                                    type = types.bool;
                                    default = false;
                                };
                            };
                        }
                    );
                    default = { };
                };
                groups = mkOption {
                    description = "User groups, by name. Apps use them to decide who gets in and with which role.";
                    type = types.attrsOf (
                        types.submodule {
                            options = {
                                friendlyName = mkOption { type = types.str; };
                                members = mkOption {
                                    type = with types; listOf str;
                                    default = [ ];
                                    description = "Usernames. The whole set: anyone not listed is taken out.";
                                };
                                claims = mkOption {
                                    type = with types; attrsOf str;
                                    default = { };
                                    description = "Custom claims every member's token carries (with the profile scope).";
                                };
                            };
                        }
                    );
                    default = { };
                };
                clients = mkOption {
                    description = "OIDC clients, by client ID. All public with PKCE: no client secret to store.";
                    type = types.attrsOf (
                        types.submodule {
                            options = {
                                name = mkOption { type = types.str; };
                                callbackURLs = mkOption { type = with types; listOf str; };
                                logoutCallbackURLs = mkOption {
                                    type = with types; listOf str;
                                    default = [ ];
                                };
                                launchURL = mkOption {
                                    type = with types; nullOr str;
                                    default = null;
                                    description = "Where the app's tile on Pocket ID's home page links to.";
                                };
                                groups = mkOption {
                                    type = with types; listOf str;
                                    default = [ ];
                                    description = "Only members of these groups may sign in. Empty: every user.";
                                };
                            };
                        }
                    );
                    default = { };
                };
            };

            config = {
                services.pocket-id = {
                    enable = true;
                    settings = {
                        APP_URL = "https://${cfg.domain}";
                        HOST = "127.0.0.1";
                        PORT = toString port;
                        # Caddy (caddy.nix) passes on the visitor's address, for rate limits and the audit log.
                        TRUST_PROXY = true;
                        ANALYTICS_DISABLED = true;
                    };
                    credentials = {
                        ENCRYPTION_KEY = "${keysDir}/encryption-key";
                        STATIC_API_KEY = "${keysDir}/api-key";
                    };
                };

                systemd.services.pocket-id-keys = {
                    description = "Create Pocket ID's encryption and API keys";
                    before = [ "pocket-id.service" ];
                    requiredBy = [ "pocket-id.service" ];
                    serviceConfig = {
                        Type = "oneshot";
                        RemainAfterExit = true;
                        UMask = "0077";
                    };
                    path = [ pkgs.openssl ];
                    script = ''
                        mkdir -p ${keysDir}
                        for key in encryption-key api-key; do
                            [ -s ${keysDir}/$key ] || openssl rand -hex 32 > ${keysDir}/$key
                        done
                    '';
                };

                systemd.services.pocket-id-provision = {
                    description = "Write Pocket ID's users, groups and clients through its API";
                    wantedBy = [ "multi-user.target" ];
                    after = [ "pocket-id.service" ];
                    requires = [ "pocket-id.service" ];
                    # Restarts whenever the script or settings change, as both are in ExecStart.
                    serviceConfig = {
                        Type = "exec";
                        ExecStart = "${provision} ${pkgs.writeText "pocket-id-provision.json" (builtins.toJSON settings)}";
                        Restart = "on-failure";
                        RestartSec = "1min";
                    };
                    startLimitBurst = 5;
                    startLimitIntervalSec = 3600;
                };

                environment.systemPackages = [ login ];

                services.caddy.virtualHosts."http://${cfg.domain}".extraConfig = ''
                    reverse_proxy 127.0.0.1:${toString port}
                '';

                # The SQLite database is dumped instead of copied live (backup.nix).
                homelab.backup = {
                    paths = [
                        dataDir
                        keysDir
                    ];
                    exclude = [ "${db}*" ];
                    # Empty until Pocket ID's first start.
                    dumps."pocket-id.sql.gz" = ''
                        { [ ! -e ${db} ] || ${lib.getExe pkgs.sqlite} -readonly ${db} .dump; } | ${lib.getExe pkgs.gzip}
                    '';
                };
            };
        };
}
