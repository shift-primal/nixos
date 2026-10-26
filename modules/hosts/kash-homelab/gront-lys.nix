_:

let
    repo = "shift-primal/gront-lys-app";
    # Images Komodo builds from the repo; the backup timer below runs one of them.
    image = env: service: "gront-lys-${env}-${service}:latest";
in
{
    # Grønt Lys, moved from Railway: staging follows `main`, production follows `production`
    # (moved by the repo's Promote workflow). The database stays on Neon and every value comes from
    # Bitwarden through varlock, so each environment only needs its BWS_ACCESS_TOKEN. What Railway
    # did around a deploy is redone here: db-setup before web and worker start, the commit the app
    # reports on /api/health, and for staging the commit status that starts the repo's Staging
    # smoke workflow. Its runbooks still describe Railway.
    flake.modules.nixos.kash-homelab =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            stacksDir = "${config.services.komodo-periphery.rootDirectory}/stacks";
            commitEnv = ".commit.env";

            # Railway set RAILWAY_GIT_COMMIT_SHA; the app reads it for /api/health and Sentry.
            writeCommit = pkgs.writeShellScript "gront-lys-commit" ''
                echo "RAILWAY_GIT_COMMIT_SHA=$(${lib.getExe pkgs.git} rev-parse HEAD)" > ${commitEnv}
            '';

            # .github/workflows/staging-smoke.yml starts on a successful status whose context ends in
            # " - web" and whose description names staging, the way Railway reported its deploys.
            stagingStatus = pkgs.writeShellScript "gront-lys-staging-status" ''
                set -eu
                . ${config.sops.templates."app-gront-lys-staging.env".path}
                ${lib.getExe pkgs.curl} -fsS -o /dev/null -X POST \
                    -H "Authorization: Bearer $GITHUB_STATUS_TOKEN" \
                    -H "Accept: application/vnd.github+json" \
                    "https://api.github.com/repos/${repo}/statuses/$(${lib.getExe pkgs.git} rev-parse HEAD)" \
                    -d '{"state":"success","context":"homelab - web","description":"Success - staging-grontlys.haugestol.com"}'
            '';

            stack =
                {
                    env,
                    branch,
                    domain,
                    port,
                    extraServices ? { },
                    extraSecrets ? [ ],
                    postDeploy ? null,
                }:
                let
                    name = "gront-lys-${env}";
                    # The checkout Komodo clones; the compose file itself lives in the store.
                    checkout = "${stacksDir}/${name}";
                    common = {
                        environment = {
                            APP_ENV = env;
                            BWS_ACCESS_TOKEN = "\${BWS_ACCESS_TOKEN}";
                            # Cloudflare is in front now, not Railway's edge (.env.schema).
                            CLIENT_IP_HEADER = "cf-connecting-ip";
                        };
                        env_file = [
                            {
                                path = "${checkout}/${commitEnv}";
                                required = false;
                            }
                        ];
                    };
                    built = service: dockerfile: {
                        image = image env service;
                        build = {
                            context = checkout;
                            inherit dockerfile;
                        };
                    };
                    afterSetup.setup.condition = "service_completed_successfully";
                in
                {
                    inherit
                        domain
                        port
                        repo
                        branch
                        ;
                    gitAccount = "shift-primal";
                    secrets = [ "BWS_ACCESS_TOKEN" ] ++ extraSecrets;
                    compose = {
                        files = [ ];
                        service = "web";
                        preDeploy = writeCommit;
                        inherit postDeploy;
                        override.services = {
                            # Railway's pre deploy command: migrations, the job queue schema, role passwords.
                            setup = common // {
                                image = image env "web";
                                pull_policy = "never";
                                command = [
                                    "varlock"
                                    "run"
                                    "--"
                                    "node"
                                    "bin/db-setup.mjs"
                                ];
                                restart = "no";
                            };
                            web =
                                common
                                // built "web" "apps/web/Dockerfile"
                                // {
                                    environment = common.environment // {
                                        PORT = "3000";
                                    };
                                    restart = "unless-stopped";
                                    depends_on = afterSetup;
                                };
                            worker =
                                common
                                // built "worker" "apps/worker/Dockerfile"
                                // {
                                    restart = "unless-stopped";
                                    depends_on = afterSetup;
                                };
                        }
                        // extraServices;
                    };
                };
        in
        {
            homelab.apps = {
                gront-lys-staging = stack {
                    env = "staging";
                    branch = "main";
                    domain = "staging-grontlys.haugestol.com";
                    port = 3007;
                    extraSecrets = [ "GITHUB_STATUS_TOKEN" ];
                    postDeploy = stagingStatus;
                };

                gront-lys-production = stack {
                    env = "production";
                    branch = "production";
                    domain = "grontlys.haugestol.com";
                    port = 3008;
                    # Built with each deploy so the timer below runs the matching backup.sh; `true`
                    # keeps `compose up` from taking a dump.
                    extraServices.backup = {
                        image = image "production" "backup";
                        build = {
                            context = "${stacksDir}/gront-lys-production";
                            dockerfile = "ops/backup/Dockerfile";
                        };
                        command = [ "true" ];
                        restart = "no";
                    };
                };
            };

            # Railway's nightly cron (docs/runbooks/backups.md): pg_dump of Neon production, age,
            # then R2. Separate from backup.nix, which only covers this host's own state.
            systemd.services.gront-lys-backup = {
                description = "Grønt Lys production database dump to R2";
                after = [ "docker.service" ];
                requires = [ "docker.service" ];
                serviceConfig.Type = "oneshot";
                script = ''
                    exec ${config.virtualisation.docker.package}/bin/docker run --rm \
                        --env-file ${config.sops.templates."app-gront-lys-production.env".path} \
                        -e APP_ENV=production \
                        ${image "production" "backup"}
                '';
            };
            systemd.timers.gront-lys-backup = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnCalendar = "*-*-* 02:00:00 UTC";
                    Persistent = true;
                };
            };
        };
}
