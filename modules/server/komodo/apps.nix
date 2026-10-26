_:

let
    # The Resource Sync to create once in the Komodo UI: name "homelab", "Files on host",
    # resource path ".". Core reads it from /syncs/<sync name>.
    syncName = "homelab";
in
{
    # Web apps built from their own git repos. Each entry gets a Komodo Build and Deployment
    # (declared through a Resource Sync generated here) plus its Caddy vhost, so the port lives in
    # one place. Komodo builds on this host and keeps the image local; nothing is pushed to a registry.
    flake.modules.nixos.komodo =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            apps = config.homelab.apps;
            hostname = config.networking.hostName;

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
                        # A push to the repo rebuilds, and redeploy_on_build rolls it out.
                        webhook_enabled = true;
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
                    };
                }) apps;
            };

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
                                type = lib.types.str;
                                description = "GitHub repo with a Dockerfile at its root, as owner/name.";
                            };
                            branch = lib.mkOption {
                                type = lib.types.str;
                                default = "main";
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
                                ports = lib.mapAttrsToList (_: app: app.port) apps;
                            in
                            lib.length ports == lib.length (lib.unique ports);
                        message = "homelab.apps: two apps share a port.";
                    }
                ];

                # A new store path per change, so Core restarts (a few seconds of UI downtime, apps
                # keep running) and the sync shows the diff to execute.
                virtualisation.oci-containers.containers.komodo-core.volumes = [
                    "${syncDir}:/syncs/${syncName}:ro"
                ];

                services.caddy.virtualHosts = lib.mapAttrs' (
                    _: app:
                    lib.nameValuePair "http://${app.domain}" {
                        extraConfig = ''
                            reverse_proxy 127.0.0.1:${toString app.port}
                        '';
                    }
                ) apps;
            };
        };
}
