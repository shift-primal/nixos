_:

let
    runnerImage = "docker.io/myoung34/github-runner:ubuntu-noble";
    dindImage = "docker.io/library/docker:29-dind";
    stateDir = "/var/lib/gha";
in
{

    #

    flake.modules.nixos.homelab =
        { config, lib, ... }:
        let
            cfg = config.homelab.githubRunners;
            docker = "${config.virtualisation.docker.package}/bin/docker";
        in
        {
            options.homelab.githubRunners = lib.mkOption {
                type = lib.types.attrsOf (
                    lib.types.submodule {
                        options.url = lib.mkOption {
                            type = lib.types.str;
                            example = "https://github.com/shift-primal/gront-lys-app";
                            description = ''
                                Repo the runner serves, or an organization (https://github.com/<org>)
                                to serve all its repos. A user account has no account-wide runners.
                            '';
                        };
                    }
                );
                default = { };
                description = ''
                    Runners by name. Each reads a fine-grained PAT from sops key github-runner/<name>:
                    for a repo, Administration read/write on it; for an org, Self-hosted runners
                    read/write, with the org as resource owner.
                '';
            };

            config =
                let
                    runners = lib.mapAttrsToList (
                        name: runner:
                        let
                            path = lib.removePrefix "https://github.com/" runner.url;
                            isOrg = !(lib.hasInfix "/" path);
                            dir = "${stateDir}/${name}";
                            dind = "gha-${name}-dind";
                        in
                        {
                            sops.secrets."github-runner/${name}" = { };
                            sops.templates."gha-${name}.env".content = ''
                                ACCESS_TOKEN=${config.sops.placeholder."github-runner/${name}"}
                            '';

                            virtualisation.oci-containers = {
                                backend = "docker";
                                containers.${dind} = {
                                    image = dindImage;
                                    privileged = true;

                                    cmd = [ "--host=unix:///var/run/docker.sock" ];
                                    volumes = [
                                        "${dir}/docker:/var/lib/docker"
                                        "${dir}/run:/var/run"

                                        "${dir}/work:/tmp/runner"
                                    ];

                                    extraOptions = [
                                        "--cpus=3"
                                        "--cpu-shares=256"
                                        "--memory=2g"
                                    ];
                                };
                                containers."gha-${name}" = {
                                    image = runnerImage;
                                    dependsOn = [ dind ];
                                    environment = {
                                        RUNNER_SCOPE = if isOrg then "org" else "repo";
                                        RUNNER_NAME = "homelab-${name}";
                                        LABELS = "homelab";
                                        EPHEMERAL = "true";
                                        RUNNER_WORKDIR = "/tmp/runner/work";
                                        DOCKER_HOST = "unix:///run/dind/docker.sock";
                                    }
                                    // (if isOrg then { ORG_NAME = path; } else { REPO_URL = runner.url; });
                                    environmentFiles = [ config.sops.templates."gha-${name}.env".path ];
                                    volumes = [
                                        "${dir}/run:/run/dind"
                                        "${dir}/work:/tmp/runner"
                                    ];
                                    extraOptions = [
                                        "--network=container:${dind}"
                                        "--cpus=3"
                                        "--cpu-shares=256"
                                        "--memory=3g"
                                    ];
                                };
                            };

                            systemd.services."docker-${dind}".preStart = lib.mkBefore ''
                                mkdir -p ${dir}/docker ${dir}/run ${dir}/work
                            '';
                            systemd.services."docker-gha-${name}" = {

                                preStart = lib.mkBefore ''

                                    find ${dir}/work -mindepth 1 -delete
                                '';

                                serviceConfig = {
                                    Restart = lib.mkForce "always";
                                    RestartSec = 30;
                                };
                            };
                        }
                    ) cfg;
                    merge = key: lib.mkMerge (map (r: r.${key}) runners);
                in
                {
                    sops = merge "sops";
                    virtualisation = merge "virtualisation";
                    systemd = lib.mkMerge [
                        (merge "systemd")
                        {

                            services.gha-prune = lib.mkIf (cfg != { }) {
                                description = "Prune the GitHub runners' Docker caches";
                                script = ''
                                    ${docker} pull ${runnerImage} || true
                                ''
                                + lib.concatMapStrings (name: ''
                                    ${docker} exec gha-${name}-dind docker system prune -af --filter until=168h || true
                                    ${docker} exec gha-${name}-dind docker volume prune -f || true
                                '') (lib.attrNames cfg);
                                serviceConfig.Type = "oneshot";
                                startAt = "weekly";
                            };
                        }
                    ];
                };
        };
}
