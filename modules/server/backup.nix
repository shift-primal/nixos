_:

{
    # Nightly off-site copy of this host's state with restic, to a private R2 bucket. The config is
    # in git, so only what a rebuild can't bring back is copied. Features add their own paths and
    # database dumps through homelab.backup (komodo/core.nix); without this aspect they won't evaluate.
    flake.modules.nixos.backup =
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

            # A live database's files can be caught mid-write, so each one is dumped first.
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
                # Containers that opt in, e.g. a Komodo stack's database:
                #   labels: { homelab.backup: postgres }
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
                # Values go in secrets/hosts/<hostname>.yaml. repository is
                # s3:https://<account id>.r2.cloudflarestorage.com/<bucket>; password encrypts the
                # repository and is the one thing a restore can't do without, so keep it in Bitwarden too.
                sops.secrets = {
                    "restic/repository" = { };
                    "restic/password" = { };
                    "restic/r2-access-key-id" = { };
                    "restic/r2-secret-access-key" = { };
                    # Ping URL of a healthchecks.io check (period 1 day, grace ~2 h), so a night
                    # with no backup alerts too, not only one that fails.
                    "healthchecks/backup-url" = { };
                };
                sops.templates."restic.env".content = ''
                    AWS_ACCESS_KEY_ID=${placeholder."restic/r2-access-key-id"}
                    AWS_SECRET_ACCESS_KEY=${placeholder."restic/r2-secret-access-key"}
                    AWS_DEFAULT_REGION=auto
                '';

                # Named volumes of Komodo stacks and other containers.
                homelab.backup.paths = lib.mkIf config.virtualisation.docker.enable [
                    "/var/lib/docker/volumes"
                ];

                # `restic-offsite snapshots` / `restore` as root, with the credentials filled in.
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
                        # A night the box was off runs at the next boot.
                        Persistent = true;
                    };
                    pruneOpts = [
                        "--keep-daily 7"
                        "--keep-weekly 5"
                        "--keep-monthly 12"
                    ];
                    # Reads back a slice of the stored data each night, so a broken repository shows
                    # up before the day it's needed. R2 doesn't charge for the download.
                    checkOpts = [ "--read-data-subset=2%" ];
                };

                # Reports each run to healthchecks.io: /start before the dumps, then success or /fail
                # with this run's log. A failed ping must not fail the backup, hence `|| true`.
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
