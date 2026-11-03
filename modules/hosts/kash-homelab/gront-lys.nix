_:

let
    repo = "shift-primal/gront-lys-app";

    image = env: service: "gront-lys-${env}-${service}:latest";
in
{

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

            writeCommit = pkgs.writeShellScript "gront-lys-commit" ''
                echo "RAILWAY_GIT_COMMIT_SHA=$(${lib.getExe pkgs.git} rev-parse HEAD)" > ${commitEnv}
            '';

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

                    checkout = "${stacksDir}/${name}";
                    common = {
                        environment = {
                            APP_ENV = env;
                            BWS_ACCESS_TOKEN = "\${BWS_ACCESS_TOKEN}";

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

                        pull_policy = "never";
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
                        oneShot = [ "setup" ] ++ lib.attrNames extraServices;
                        preDeploy = writeCommit;
                        inherit postDeploy;
                        override.services = {

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

                    extraServices.backup = {
                        image = image "production" "backup";
                        build = {
                            context = "${stacksDir}/gront-lys-production";
                            dockerfile = "ops/backup/Dockerfile";
                        };
                        pull_policy = "never";
                        command = [ "true" ];
                        restart = "no";
                    };
                };
            };

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
