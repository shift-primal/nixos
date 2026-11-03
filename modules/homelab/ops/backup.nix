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
            cfg = config.homelab.backup;
            dumpDir = "/var/backup/dumps";
            docker = "${config.virtualisation.docker.package}/bin/docker";
            inherit (config.sops) placeholder;

            dump = pkgs.writeShellScript "backup-dumps" ''
                set -euo pipefail
                umask 077
                rm -rf ${dumpDir}
                mkdir -p ${dumpDir}
                ${lib.concatStrings (
                    lib.mapAttrsToList (name: command: ''
                        ${lib.trim command} > ${dumpDir}/${name}
                    '') cfg.dumps
                )}


                for c in $(${docker} ps --filter label=homelab.backup=postgres --format '{{.Names}}'); do
                    ${docker} exec "$c" sh -c 'exec pg_dumpall --username "$POSTGRES_USER"' |
                        ${lib.getExe pkgs.gzip} > "${dumpDir}/$c.sql.gz"
                done
            '';
        in
        {
            options.homelab.backup = {
                paths = lib.mkOption {
                    type = with lib.types; listOf str;
                    default = [ ];
                    description = "Paths copied every night.";
                };
                exclude = lib.mkOption {
                    type = with lib.types; listOf str;
                    default = [ ];
                    description = "Paths left out, such as live database files that are dumped instead.";
                };
                dumps = lib.mkOption {
                    type = with lib.types; attrsOf str;
                    default = { };
                    description = "Commands whose output is saved as ${dumpDir}/<name> right before each backup.";
                };
            };

            config = {

                sops.secrets = {
                    "restic/repository" = { };
                    "restic/password" = { };
                    "restic/r2-access-key-id" = { };
                    "restic/r2-secret-access-key" = { };

                    "healthchecks/backup-url" = { };
                };
                sops.templates."restic.env".content = ''
                    AWS_ACCESS_KEY_ID=${placeholder."restic/r2-access-key-id"}
                    AWS_SECRET_ACCESS_KEY=${placeholder."restic/r2-secret-access-key"}
                    AWS_DEFAULT_REGION=auto
                '';

                homelab.backup.paths = lib.mkIf config.virtualisation.docker.enable [
                    "/var/lib/docker/volumes"
                ];

                services.restic.backups.offsite = {
                    repositoryFile = config.sops.secrets."restic/repository".path;
                    passwordFile = config.sops.secrets."restic/password".path;
                    environmentFile = config.sops.templates."restic.env".path;
                    initialize = true;
                    paths = cfg.paths ++ [ dumpDir ];
                    inherit (cfg) exclude;
                    backupPrepareCommand = "${dump}";
                    timerConfig = {
                        OnCalendar = "03:00";
                        RandomizedDelaySec = "30m";

                        Persistent = true;
                    };
                    pruneOpts = [
                        "--keep-daily 7"
                        "--keep-weekly 5"
                        "--keep-monthly 12"
                    ];

                    checkOpts = [ "--read-data-subset=2%" ];
                };

                systemd.services.restic-backups-offsite =
                    let
                        ping = "${lib.getExe pkgs.curl} -fsS -m 10 --retry 5 -o /dev/null";
                        url = "$(cat ${config.sops.secrets."healthchecks/backup-url".path})";
                    in
                    {
                        preStart = lib.mkBefore ''
                            ${ping} "${url}/start" || true
                        '';
                        postStop = ''
                            if [ "$SERVICE_RESULT" = success ]; then
                                ${ping} "${url}" || true
                            else
                                ${config.systemd.package}/bin/journalctl -o cat -n 100 \
                                    _SYSTEMD_INVOCATION_ID="$INVOCATION_ID" |
                                    ${ping} --data-binary @- "${url}/fail" || true
                            fi
                        '';
                    };
            };
        };
}
