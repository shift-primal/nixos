_:

let
    runnerImage = "docker.io/myoung34/github-runner:ubuntu-noble";
    dindImage = "docker.io/library/docker:29-dind";
    stateDir = "/var/lib/gha";
in
{
    # Self-hosted GitHub Actions runners, so private repos stop spending billed minutes (public
    # repos run free on GitHub's own runners and must never use these: a fork PR would run its code
    # here). A workflow opts in with `runs-on: [self-hosted, homelab]`.
    #
    # Each runner is an Ubuntu container, so workflows written for ubuntu-latest (setup-node,
    # `playwright install --with-deps`, apt) run unchanged, next to its own Docker daemon (dind) for
    # `services:` and `docker build`. Sharing its network namespace, job steps reach service
    # containers on localhost as on GitHub, two runners can both publish 5432, and nothing is
    # published on this host. dind is privileged, so a job can get root here: only attach repos
    # whose every writer you trust. Ephemeral: one job per container, then a fresh one registers.
    flake.modules.nixos.github-runners =
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

            # Built per runner, then merged per top-level option: merging whole configs computed from
            # cfg would recurse, since the module system can't tell they don't define cfg itself.
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
                                    # Socket only: dind's default TCP 2375 would be reachable without
                                    # auth from every container on the host's bridge.
                                    cmd = [ "--host=unix:///var/run/docker.sock" ];
                                    volumes = [
                                        "${dir}/docker:/var/lib/docker"
                                        "${dir}/run:/var/run"
                                        # Same path in both, so bind mounts of the workspace into
                                        # job containers (Docker actions, `container:` jobs) find it.
                                        "${dir}/work:/tmp/runner"
                                    ];
                                    # Lower CPU weight than everything else, so Jellyfin and the apps
                                    # win. Two busy runners can take 10 of the 12 GB: add more with care.
                                    extraOptions = [
                                        "--cpus=3"
                                        "--cpu-shares=256"
                                        "--memory=2g"
                                    ];
                                };
                                containers."gha-${name}" = {
                                    image = runnerImage;
                                    # The runner updates itself when GitHub requires it; pulling on
                                    # each start keeps a fresh container from redoing that every job.
                                    pull = "newer";
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
                                # A clean workspace for every job, like GitHub's runners.
                                preStart = lib.mkBefore ''
                                    # Emptied, not recreated: dind holds a bind mount of this directory.
                                    find ${dir}/work -mindepth 1 -delete
                                '';
                                # An ephemeral runner exits 0 after its job; start the next one.
                                serviceConfig = {
                                    Restart = lib.mkForce "always";
                                    RestartSec = 5;
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
                            # dind keeps images (postgres, build cache) between jobs for speed; drop
                            # what no job used in a week.
                            services.gha-prune = lib.mkIf (cfg != { }) {
                                description = "Prune the GitHub runners' Docker caches";
                                script = lib.concatMapStrings (name: ''
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
