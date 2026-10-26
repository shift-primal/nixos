_:

let
    # The Resource Sync to create once in the Komodo UI: name "homelab", "Files on host",
    # resource path ".". Core reads it from /syncs/<sync name>.
    syncName = "homelab";
in
{
    # Web apps built from their own git repos. Each entry gets a Komodo Build and Deployment, or a
    # Stack when it ships its own compose file (declared through a Resource Sync generated here),
    # plus its Caddy vhost, so the port lives in one place. Komodo builds on this host and keeps the
    # images local; nothing is pushed to a registry.
    flake.modules.nixos.komodo =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            apps = lib.filterAttrs (_: app: app.compose == null) config.homelab.apps;
            stacks = lib.filterAttrs (_: app: app.compose != null) config.homelab.apps;
            allApps = config.homelab.apps;
            hostname = config.networking.hostName;
            periphery = config.services.komodo-periphery;
            inherit (config.sops) placeholder;

            secretName = name: key: "apps/${name}/${key}";
            envFile = name: "app-${name}.env";
            # Komodo reads these as `KEY = value` lines.
            lines = attrs: lib.concatLines (lib.mapAttrsToList (k: v: "${k} = ${v}") attrs);

            resources = {
                builder = [
                    {
                        name = hostname;
                        config = {
                            type = "Server";
                            params.server = hostname;
                        };
                    }
                ];
                build = lib.mapAttrsToList (name: app: {
                    inherit name;
                    config = {
                        builder = hostname;
                        inherit (app) repo branch;
                        git_account = app.gitAccount;
                        # A push to the repo rebuilds, and redeploy_on_build rolls it out.
                        webhook_enabled = true;
                    }
                    // lib.optionalAttrs (app.buildFiles != { }) {
                        # Runs in the fresh checkout on this host, so the file never reaches git
                        # or the store.
                        pre_build.command = lib.concatLines (
                            lib.mapAttrsToList (
                                path: secret: "cp ${config.sops.secrets.${secretName name secret}.path} ${path}"
                            ) app.buildFiles
                        );
                    };
                }) apps;
                deployment = lib.mapAttrsToList (name: app: {
                    inherit name;
                    config = {
                        server = hostname;
                        image = {
                            type = "Build";
                            params.build = name;
                        };
                        redeploy_on_build = true;
                        # Komodo defaults to the host network, which would ignore the port binding.
                        network = "bridge";
                        restart = "unless-stopped";
                        # Localhost only: Docker bypasses the firewall, and Caddy is the way in.
                        ports = "127.0.0.1:${toString app.port}:${toString app.containerPort}";
                        environment = lines app.environment;
                        # Named volumes land in /var/lib/docker/volumes, which backup.nix copies.
                        volumes = lines app.volumes;
                    }
                    // lib.optionalAttrs (app.secrets != [ ]) {
                        # Read by the docker CLI, which Periphery runs as its own user.
                        extra_args = [ "--env-file=${config.sops.templates.${envFile name}.path}" ];
                    };
                }) apps;
                stack = lib.mapAttrsToList (name: app: {
                    inherit name;
                    config = {
                        server = hostname;
                        environment = lines app.environment;
                        ignore_services = app.compose.oneShot;
                    }
                    // (
                        if app.repo != null then
                            {
                                inherit (app) repo branch;
                                git_account = app.gitAccount;
                                # Builds the compose file's `build:` services, so a push redeploys from source.
                                run_build = true;
                                webhook_enabled = true;
                                # The override is a store path; compose takes absolute -f paths as they are.
                                file_paths = app.compose.files ++ [ "${override name app}" ];
                            }
                        else
                            {
                                file_contents = lib.generators.toYAML { } (composeWithPort app);
                                # Prebuilt images: redeploy when a newer one is pushed.
                                poll_for_updates = true;
                                auto_update = true;
                            }
                    )
                    // lib.optionalAttrs (app.compose.preDeploy != null) {
                        pre_deploy.command = "${app.compose.preDeploy}";
                    }
                    // lib.optionalAttrs (app.compose.postDeploy != null) {
                        post_deploy.command = "${app.compose.postDeploy}";
                    }
                    // lib.optionalAttrs (app.secrets != [ ]) {
                        # For ${VAR} interpolation in the compose file. Untracked, so Komodo never
                        # reads or shows the values.
                        additional_env_files = [
                            {
                                path = config.sops.templates.${envFile name}.path;
                                track = false;
                            }
                        ];
                    };
                }) stacks;
            };

            # Binds the served container to localhost (Docker bypasses the firewall, and Caddy is the
            # way in), on top of whatever the stack's own override adds.
            composeWithPort =
                app:
                lib.recursiveUpdate {
                    services.${app.compose.service}.ports = [
                        "127.0.0.1:${toString app.port}:${toString app.containerPort}"
                    ];
                } app.compose.override;
            override = name: app: (pkgs.formats.yaml { }).generate "${name}-override.yml" (composeWithPort app);

            # Copied rather than linked: Core's container can't follow links into /nix/store.
            syncDir = pkgs.runCommand "komodo-sync-${syncName}" { } ''
                mkdir $out
                cp ${(pkgs.formats.toml { }).generate "apps.toml" resources} $out/apps.toml
            '';
        in
        {
            options.homelab.apps = lib.mkOption {
                default = { };
                description = "Web apps Komodo builds from git and Caddy serves.";
                type = lib.types.attrsOf (
                    lib.types.submodule {
                        options = {
                            domain = lib.mkOption {
                                type = lib.types.str;
                                description = "Public hostname, routed to the tunnel with `cloudflared tunnel route dns`.";
                            };
                            port = lib.mkOption {
                                type = lib.types.port;
                                description = "Host port on 127.0.0.1. Unique per app.";
                            };
                            containerPort = lib.mkOption {
                                type = lib.types.port;
                                default = 3000;
                                description = "Port the app listens on inside its container.";
                            };
                            repo = lib.mkOption {
                                type = with lib.types; nullOr str;
                                default = null;
                                description = ''
                                    GitHub repo with a Dockerfile at its root (or the compose files), as
                                    owner/name. Only a `compose` app of prebuilt images goes without.
                                '';
                            };
                            branch = lib.mkOption {
                                type = lib.types.str;
                                default = "main";
                            };
                            gitAccount = lib.mkOption {
                                type = lib.types.str;
                                default = "";
                                description = "Komodo git account (Settings, Providers) for a private repo.";
                            };
                            environment = lib.mkOption {
                                type = with lib.types; attrsOf str;
                                default = { };
                                description = "Plain environment variables. Anything secret goes in `secrets`.";
                            };
                            secrets = lib.mkOption {
                                type = with lib.types; listOf str;
                                default = [ ];
                                description = ''
                                    Environment variables whose values come from sops, as apps/<app>/<VAR> in
                                    secrets/hosts/<hostname>.yaml. Changing one needs a Redeploy in Komodo.
                                '';
                            };
                            buildFiles = lib.mkOption {
                                type = with lib.types; attrsOf str;
                                default = { };
                                description = "Files copied into the checkout before the build: path in the repo -> sops key under apps/<app>/.";
                                example = {
                                    "src/config/questions.data.ts" = "questions";
                                };
                            };
                            volumes = lib.mkOption {
                                type = with lib.types; attrsOf str;
                                default = { };
                                description = "Named volume or host path -> path in the container.";
                            };
                            compose = lib.mkOption {
                                default = null;
                                description = ''
                                    Deploy the repo's own compose file as a Komodo Stack instead. `secrets`
                                    then feed the file's ''${VAR} interpolation; `volumes` and `buildFiles`
                                    don't apply (put volumes in the compose file or `override`).
                                '';
                                type = lib.types.nullOr (
                                    lib.types.submodule {
                                        options = {
                                            files = lib.mkOption {
                                                type = with lib.types; listOf str;
                                                default = [ "compose.yaml" ];
                                                description = "Compose files in the repo.";
                                            };
                                            service = lib.mkOption {
                                                type = lib.types.str;
                                                default = "app";
                                                description = "Service Caddy proxies to.";
                                            };
                                            override = lib.mkOption {
                                                type = lib.types.attrs;
                                                default = { };
                                                description = ''
                                                    Compose override, e.g. labels for backup.nix. With no `repo`, this is
                                                    the whole compose file.
                                                '';
                                            };
                                            oneShot = lib.mkOption {
                                                type = with lib.types; listOf str;
                                                default = [ ];
                                                description = ''
                                                    Services that run once per deploy and exit (migrations, seeds). Komodo leaves
                                                    them out of the stack's health, which would otherwise read "unhealthy".
                                                '';
                                            };
                                            preDeploy = lib.mkOption {
                                                type = with lib.types; nullOr path;
                                                default = null;
                                                description = "Script Komodo runs in the stack's directory before `compose up`.";
                                            };
                                            postDeploy = lib.mkOption {
                                                type = with lib.types; nullOr path;
                                                default = null;
                                                description = "Script Komodo runs in the stack's directory after `compose up`.";
                                            };
                                        };
                                    }
                                );
                            };
                        };
                    }
                );
            };

            config = {
                assertions = [
                    {
                        assertion =
                            let
                                ports = lib.mapAttrsToList (_: app: app.port) allApps;
                            in
                            lib.length ports == lib.length (lib.unique ports);
                        message = "homelab.apps: two apps share a port.";
                    }
                    {
                        assertion = lib.all (app: app.repo != null) (lib.attrValues apps);
                        message = "homelab.apps: an app without `compose` needs a `repo` to build.";
                    }
                ];

                sops.secrets = lib.mkMerge (
                    lib.mapAttrsToList (
                        name: app:
                        lib.genAttrs (map (secretName name) (app.secrets ++ lib.attrValues app.buildFiles)) (_: {
                            owner = periphery.user;
                        })
                    ) allApps
                );

                sops.templates = lib.mapAttrs' (
                    name: app:
                    lib.nameValuePair (envFile name) {
                        owner = periphery.user;
                        content = lib.concatLines (map (key: "${key}=${placeholder.${secretName name key}}") app.secrets);
                    }
                ) (lib.filterAttrs (_: app: app.secrets != [ ]) allApps);

                # A new store path per change, so Core restarts (a few seconds of UI downtime, apps
                # keep running) and the sync shows the diff to execute.
                virtualisation.oci-containers.containers.komodo-core.volumes = [
                    "${syncDir}:/syncs/${syncName}:ro"
                ];

                # Only the tunnel reaches Caddy, so Cloudflare's CF-Connecting-IP is the real client.
                # Without it every visitor looks like cloudflared on 127.0.0.1.
                services.caddy.virtualHosts = lib.mapAttrs' (
                    _: app:
                    lib.nameValuePair "http://${app.domain}" {
                        extraConfig = ''
                            reverse_proxy 127.0.0.1:${toString app.port} {
                                header_up X-Forwarded-For {header.CF-Connecting-IP}
                            }
                        '';
                    }
                ) allApps;
            };
        };
}
