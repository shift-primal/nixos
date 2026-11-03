{ config, ... }:

let
    inherit (config) vars;
in
{

    flake.modules.nixos.homelab =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            hub = config.services.beszel.hub;
            hostName = config.networking.hostName;

            keysDir = "/var/lib/beszel-keys";
            agentPort = 45876;
            api = "http://127.0.0.1:${toString hub.port}/api";

            configYml = (pkgs.formats.yaml { }).generate "beszel-config.yml" {
                systems = [
                    {
                        name = hostName;
                        host = "127.0.0.1";
                        port = agentPort;
                        users = [ config.homelab.beszel.email ];
                    }
                ];
            };

            alerts = {
                Status = {
                    value = 0;
                    min = 2;
                };
                CPU = {
                    value = 90;
                    min = 10;
                };
                Memory = {
                    value = 90;
                    min = 10;
                };
                Disk = {
                    value = 85;
                    min = 10;
                };
                Temperature = {
                    value = 85;
                    min = 5;
                };
                SystemdFailed = {
                    value = 0;
                    min = 0;
                };
            };

            configure = pkgs.writeShellApplication {
                name = "beszel-configure";
                runtimeInputs = with pkgs; [
                    curl
                    jq
                ];
                text = ''

                    for i in $(seq 60); do
                        curl -fs -o /dev/null ${api}/health && break
                        [ "$i" -lt 60 ] || { echo "hub not answering on ${api}" >&2; exit 1; }
                        sleep 2
                    done

                    auth=$(jq -n --arg e ${lib.escapeShellArg config.homelab.beszel.email} \
                        --rawfile p ${keysDir}/password '{identity: $e, password: ($p | rtrimstr("\n"))}' |
                        curl -fsS -H 'Content-Type: application/json' -d @- \
                            ${api}/collections/users/auth-with-password)
                    token=$(jq -r .token <<< "$auth")
                    user=$(jq -r .record.id <<< "$auth")
                    call() { curl -fsS -H "Authorization: $token" -H 'Content-Type: application/json' "$@"; }


                    su=$(jq -n --arg e ${lib.escapeShellArg config.homelab.beszel.email} \
                        --rawfile p ${keysDir}/password '{identity: $e, password: ($p | rtrimstr("\n"))}' |
                        curl -fsS -H 'Content-Type: application/json' -d @- \
                            ${api}/collections/_superusers/auth-with-password | jq -r .token)
                    sucall() { curl -fsS -H "Authorization: $su" -H 'Content-Type: application/json' "$@"; }


                    system=""
                    until [ -n "$system" ]; do
                        system=$(call -G ${api}/collections/systems/records \
                            --data-urlencode "filter=name='${hostName}'" | jq -r '.items[0].id // empty')
                        [ -n "$system" ] || sleep 2
                    done


                    ntfy="$(sed 's|^https://|ntfy://|' ${
                        config.sops.secrets."ntfy/url".path
                    })?priority=high&tags=warning"
                    settings=$(call -G ${api}/collections/user_settings/records \
                        --data-urlencode "filter=user='$user'" | jq '.items[0] // empty')
                    if [ -z "$settings" ]; then
                        settings=$(call -d "$(jq -n --arg u "$user" '{user: $u, settings: {}}')" \
                            ${api}/collections/user_settings/records)
                    fi
                    jq --arg n "$ntfy" '{settings: (.settings + {webhooks: [$n], emails: []})}' <<< "$settings" |
                        call -X PATCH -d @- "${api}/collections/user_settings/records/$(jq -r .id <<< "$settings")" > /dev/null



                    sucall -G ${api}/collections/users/records --data-urlencode "filter=role='readonly'" |
                        jq -r '.items[].id' | while read -r id; do
                            sucall -X DELETE "${api}/collections/users/records/$id"
                        done
                    jq -n --arg u "$user" '{users: [$u]}' |
                        sucall -X PATCH -d @- "${api}/collections/systems/records/$system" > /dev/null

                    ${lib.concatStrings (
                        lib.mapAttrsToList (name: a: ''
                            call -d "$(jq -n --arg s "$system" '{name: "${name}", value: ${toString a.value}, min: ${toString a.min}, systems: [$s], overwrite: true}')" \
                                ${api}/beszel/user-alerts > /dev/null
                        '') alerts
                    )}
                    echo "ntfy webhook and ${toString (builtins.length (builtins.attrNames alerts))} alert rules set for ${hostName}"
                '';
            };
        in
        {
            options.homelab.beszel.email = lib.mkOption {
                type = lib.types.str;
                default = "${vars.user.name}@${hostName}.local";
                description = "Login of the Beszel account. Only a username: no mail is sent to it.";
            };

            config = {
                services.beszel.hub = {
                    enable = true;
                    host = "127.0.0.1";

                    environmentFile = "${keysDir}/hub.env";
                };

                systemd.services.beszel-hub = {
                    requires = [ "beszel-keys.service" ];
                    after = [ "beszel-keys.service" ];
                    serviceConfig.LoadCredential = [ "id_ed25519:${keysDir}/id_ed25519" ];

                    preStart = ''
                        mkdir -p beszel_data
                        install -m 600 "$CREDENTIALS_DIRECTORY/id_ed25519" beszel_data/id_ed25519
                        install -m 640 ${configYml} beszel_data/config.yml
                    '';
                };

                services.beszel.agent = {
                    enable = true;

                    smartmon.enable = true;
                    environment = {
                        LISTEN = "127.0.0.1:${toString agentPort}";
                        KEY_FILE = "%d/hub.pub";
                    };
                };
                systemd.services.beszel-agent = {
                    requires = [ "beszel-keys.service" ];
                    after = [ "beszel-keys.service" ];
                    serviceConfig.LoadCredential = [ "hub.pub:${keysDir}/id_ed25519.pub" ];
                };

                systemd.services.beszel-keys = {
                    description = "Create Beszel's account password and hub SSH key";
                    serviceConfig = {
                        Type = "oneshot";
                        RemainAfterExit = true;
                        UMask = "0077";
                    };
                    path = with pkgs; [
                        openssl
                        openssh
                    ];
                    script = ''
                        mkdir -p ${keysDir}
                        cd ${keysDir}
                        [ -s password ] || openssl rand -hex 24 > password
                        [ -s id_ed25519 ] || ssh-keygen -q -t ed25519 -N "" -C beszel-hub -f id_ed25519
                        printf 'USER_EMAIL=%s\nUSER_PASSWORD=%s\n' \
                            ${lib.escapeShellArg config.homelab.beszel.email} "$(cat password)" > hub.env

                        printf 'HOMEPAGE_VAR_BESZEL_PASSWORD=%s\n' "$(cat password)" > homepage.env
                    '';
                };

                systemd.services.beszel-configure = {
                    description = "Write Beszel's ntfy URL and alert rules through its API";
                    wantedBy = [ "multi-user.target" ];
                    after = [ "beszel-hub.service" ];
                    requires = [ "beszel-hub.service" ];

                    serviceConfig = {
                        Type = "exec";
                        ExecStart = lib.getExe configure;
                        Restart = "on-failure";
                        RestartSec = "1min";
                    };
                    startLimitBurst = 5;
                    startLimitIntervalSec = 3600;
                };

                homelab.tailscaleHttps = [ hub.port ];

                homelab.backup.paths = [ keysDir ];
            };
        };
}
