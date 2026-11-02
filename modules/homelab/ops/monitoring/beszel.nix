{ config, ... }:

let
    inherit (config) vars;
in
{
    # Beszel: CPU, memory, disk, network, temperature, per-container (Docker) and systemd history for
    # this host, with alerts pushed through ntfy (ntfy.nix). Tailscale only, at
    # https://<host>.<tailnet>.ts.net:8090 (edge/tailscale-https.nix); never on the tunnel.
    # The hub reads the agent over SSH on 127.0.0.1. Everything it would otherwise ask for in the UI
    # is set here: the account and SSH key are made on the box on first start (beszel-keys), the
    # system comes from config.yml, and beszel-configure writes the ntfy URL and alert rules.
    # Log in as `homelab.beszel.email` with the password from `sudo cat /var/lib/beszel-keys/password`.
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
            # Made here, so the repo holds no secret and a new install needs no sops step.
            keysDir = "/var/lib/beszel-keys";
            agentPort = 45876;
            api = "http://127.0.0.1:${toString hub.port}/api";

            # Synced into the hub on every start: systems not listed here are deleted.
            configYml = (pkgs.formats.yaml { }).generate "beszel-config.yml" {
                systems = [
                    {
                        name = hostName;
                        host = "127.0.0.1";
                        port = agentPort;
                    }
                ];
            };

            # Name → threshold (value) and how many minutes it must hold (min) before alerting.
            # Disk covers / and the agent's EXTRA_FILESYSTEMS (hosts/kash-homelab/data.nix). Status: agent unreachable.
            # SystemdFailed: any failed unit, e.g. the backup or media-configure. SMART warnings and
            # failures alert without a rule; smartd.nix still runs the self-tests.
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
                    # The hub takes a few seconds to listen after a switch; give up (and let systemd retry) after 2 min.
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

                    # Created from config.yml as the hub starts.
                    system=""
                    until [ -n "$system" ]; do
                        system=$(call -G ${api}/collections/systems/records \
                            --data-urlencode "filter=name='${hostName}'" | jq -r '.items[0].id // empty')
                        [ -n "$system" ] || sleep 2
                    done

                    # https://ntfy.sh/<topic> → Shoutrrr's ntfy://ntfy.sh/<topic>. No email: no SMTP set up.
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
                    # USER_EMAIL and USER_PASSWORD: read once, by the migration that creates the database.
                    environmentFile = "${keysDir}/hub.env";
                };

                systemd.services.beszel-hub = {
                    requires = [ "beszel-keys.service" ];
                    after = [ "beszel-keys.service" ];
                    serviceConfig.LoadCredential = [ "id_ed25519:${keysDir}/id_ed25519" ];
                    # The hub keeps its SSH key and config.yml in its PocketBase data dir.
                    preStart = ''
                        mkdir -p beszel_data
                        install -m 600 "$CREDENTIALS_DIRECTORY/id_ed25519" beszel_data/id_ed25519
                        install -m 640 ${configYml} beszel_data/config.yml
                    '';
                };

                services.beszel.agent = {
                    enable = true;
                    # Disk health and temperatures, with -n standby so the HDD stays spun down.
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
                    '';
                };

                systemd.services.beszel-configure = {
                    description = "Write Beszel's ntfy URL and alert rules through its API";
                    wantedBy = [ "multi-user.target" ];
                    after = [ "beszel-hub.service" ];
                    requires = [ "beszel-hub.service" ];
                    # Restarts whenever the script changes, as it is in ExecStart.
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

                # The password and key, so a restored hub keeps its login and the agent still trusts it.
                # The metrics history isn't worth the backup space.
                homelab.backup.paths = [ keysDir ];
            };
        };
}
