_:

let

    syncName = "homelab";
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
            allApps = config.homelab.apps;
            hostname = config.networking.hostName;
            periphery = config.services.komodo-periphery;
            inherit (config.sops) placeholder;

            secretName = name: key: "apps/${name}/${key}";
            envFile = name: "app-${name}.env";

            lines = attrs: lib.concatLines (lib.mapAttrsToList (k: v: "${k} = ${v}") attrs);

            single = name: app: {
                files = [ ];
                service = "app";
                oneShot = [ ];
                preDeploy = null;
                postDeploy = null;
                override = {
                    services.app = {
                        image = "${name}:latest";
                        build.context = "${periphery.rootDirectory}/stacks/${name}";

                        pull_policy = "never";
                        restart = "unless-stopped";
                        inherit (app) environment;
                    }
                    // lib.optionalAttrs app.hostNetwork {
                        network_mode = "host";

                        environment = app.environment // {
                            HOST = "127.0.0.1";
                            PORT = toString app.port;
                        };
                    }
                    // lib.optionalAttrs (app.secrets != [ ]) {
                        env_file = [ config.sops.templates.${envFile name}.path ];
                    }
                    // lib.optionalAttrs (app.volumes != { }) {
                        volumes = lib.mapAttrsToList (source: target: "${source}:${target}") app.volumes;
                    };
                }
                // lib.optionalAttrs (namedVolumes app != { }) {

                    volumes = lib.mapAttrs (volume: _: { name = volume; }) (namedVolumes app);
                };
            };
            namedVolumes = app: lib.filterAttrs (source: _: !lib.hasPrefix "/" source) app.volumes;
            composeOf = name: app: if app.compose != null then app.compose else single name app;

            resources.stack = lib.mapAttrsToList (
                name: app:
                let
                    compose = composeOf name app;
                in
                {
                    inherit name;
                    config = {
                        server = hostname;
                        environment = lines app.environment;
                        ignore_services = compose.oneShot;
                    }
                    // (
                        if app.repo != null then
                            {
                                inherit (app) repo branch;
                                git_account = app.gitAccount;

                                run_build = true;
                                webhook_enabled = true;

                                webhook_force_deploy = true;

                                file_paths = compose.files ++ [ (overridePath name) ];
                            }
                        else
                            {
                                file_contents = lib.generators.toYAML { } (composeWithPort compose app);

                                poll_for_updates = true;
                                auto_update = true;
                            }
                    )
                    // lib.optionalAttrs (compose.preDeploy != null) {
                        pre_deploy.command = "${compose.preDeploy}";
                    }
                    // lib.optionalAttrs (compose.postDeploy != null) {
                        post_deploy.command = "${compose.postDeploy}";
                    }
                    // lib.optionalAttrs (app.secrets != [ ]) {

                        additional_env_files = [
                            {
                                path = config.sops.templates.${envFile name}.path;
                                track = false;
                            }
                        ];
                    };
                }
            ) allApps;

            composeWithPort =
                compose: app:
                lib.recursiveUpdate (lib.optionalAttrs (!app.hostNetwork) {
                    services.${compose.service}.ports = [
                        "127.0.0.1:${toString app.port}:${toString app.containerPort}"
                    ];
                }) compose.override;
            override =
                name: compose: app:
                (pkgs.formats.yaml { }).generate "${name}-override.yml" (composeWithPort compose app);
            overrideFile = name: "komodo/stacks/${name}-override.yml";
            overridePath = name: "/etc/${overrideFile name}";

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
                                type = with lib.types; nullOr str;
                                default = null;
                                description = "Public hostname, routed to the tunnel with `cloudflared tunnel route dns`.";
                            };
                            localNames = lib.mkOption {
                                type = with lib.types; listOf str;
                                default = [ ];
                                description = "Names on the home LAN (*.local, over mDNS) and tailnet (homelab/edge/local-names.nix).";
                            };
                            frontPage = lib.mkOption {
                                type = lib.types.bool;
                                default = false;
                                description = "Also serve the app at http://<hostname>, the host's Tailscale MagicDNS name.";
                            };
                            hostNetwork = lib.mkOption {
                                type = lib.types.bool;
                                default = false;
                                description = ''
                                    Run the container on the host's network, so it reaches every service on
                                    127.0.0.1 (the hub's status checks). The app must listen on $HOST:$PORT,
                                    which are set to 127.0.0.1 and `port`. Not for `compose` apps.
                                '';
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
                            volumes = lib.mkOption {
                                type = with lib.types; attrsOf str;
                                default = { };
                                description = ''
                                    Named volume or host path -> path in the container. Named volumes land in
                                    /var/lib/docker/volumes, which backup.nix copies.
                                '';
                            };
                            compose = lib.mkOption {
                                default = null;
                                description = ''
                                    Deploy the repo's own compose file instead of building its Dockerfile.
                                    `secrets` then feed the file's ''${VAR} interpolation; `volumes` doesn't
                                    apply (put volumes in the compose file or `override`).
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
                        assertion = lib.all (app: app.compose != null || app.repo != null) (lib.attrValues allApps);
                        message = "homelab.apps: an app without `compose` needs a `repo` to build.";
                    }
                    {
                        assertion = lib.all (app: app.hostNetwork -> app.compose == null) (lib.attrValues allApps);
                        message = "homelab.apps: `hostNetwork` only applies to an app built from its Dockerfile.";
                    }
                    {
                        assertion = lib.all (app: app.domain != null || app.localNames != [ ] || app.frontPage) (
                            lib.attrValues allApps
                        );
                        message = "homelab.apps: an app needs a `domain`, `localNames` or `frontPage` to be reachable.";
                    }
                    {
                        assertion = lib.count (app: app.frontPage) (lib.attrValues allApps) <= 1;
                        message = "homelab.apps: only one app can be the `frontPage`.";
                    }
                ];

                sops.secrets = lib.mkMerge (
                    lib.mapAttrsToList (
                        name: app:
                        lib.genAttrs (map (secretName name) app.secrets) (_: {
                            owner = periphery.user;
                        })
                    ) allApps
                );

                environment.etc = lib.mapAttrs' (
                    name: app:
                    lib.nameValuePair (overrideFile name) { source = override name (composeOf name app) app; }
                ) (lib.filterAttrs (_: app: app.repo != null) allApps);

                sops.templates = lib.mapAttrs' (
                    name: app:
                    lib.nameValuePair (envFile name) {
                        owner = periphery.user;
                        content = lib.concatLines (map (key: "${key}=${placeholder.${secretName name key}}") app.secrets);
                    }
                ) (lib.filterAttrs (_: app: app.secrets != [ ]) allApps);

                virtualisation.oci-containers.containers.komodo-core.volumes = [
                    "${syncDir}:/syncs/${syncName}:ro"
                ];

                services.caddy.virtualHosts = lib.mapAttrs' (
                    _: app:
                    lib.nameValuePair "http://${app.domain}" {
                        extraConfig = ''
                            reverse_proxy 127.0.0.1:${toString app.port} {
                                header_up X-Forwarded-For {header.CF-Connecting-IP}
                            }
                        '';
                    }
                ) (lib.filterAttrs (_: app: app.domain != null) allApps);

                homelab.localNames = lib.mkMerge (
                    lib.mapAttrsToList (
                        _: app: lib.genAttrs (app.localNames ++ lib.optional app.frontPage hostname) (_: app.port)
                    ) allApps
                );
            };
        };
}
