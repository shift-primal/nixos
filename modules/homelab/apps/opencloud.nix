_:

{
    # OpenCloud: files in the browser, sync apps for desktop and phone, share links. Public through
    # the tunnel so the apps sync from anywhere; login goes through Pocket ID (pocket-id.nix), so
    # passkeys only, and only the users listed in homelab.drive.users. Its own login (idp) is off.
    flake.modules.nixos.homelab =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            cfg = config.homelab.drive;
            inherit (config.services.opencloud) stateDir port;
            url = "https://${cfg.domain}";
            idp = "https://${config.homelab.pocketId.domain}";

            # Role per user → Pocket ID group, whose custom claim "roles" OpenCloud maps to its own role
            # (PROXY_ROLE_ASSIGNMENT_DRIVER below; the claim values are OpenCloud's defaults).
            roles = {
                admin = "opencloudAdmin";
                user = "opencloudUser";
            };
            group = role: "opencloud-${role}s";
            # Every OpenCloud user may sign in to every OpenCloud app; nobody else may.
            allowed = map group (lib.attrNames roles);

            # The web app may talk to and frame the login page; merged into OpenCloud's default policy.
            csp = (pkgs.formats.yaml { }).generate "opencloud-csp.yaml" {
                directives = lib.genAttrs [
                    "connect-src"
                    "frame-src"
                    "script-src"
                ] (_: [ "${idp}/" ]);
            };
        in
        {
            options.homelab.drive = {
                domain = lib.mkOption {
                    type = lib.types.str;
                    description = "Domain OpenCloud is served on.";
                    example = "drive.example.com";
                };
                users = lib.mkOption {
                    type = with lib.types; attrsOf (enum (lib.attrNames roles));
                    description = "Pocket ID users (homelab.pocketId.users) who may use OpenCloud, and their role.";
                    example = {
                        alice = "admin";
                        bob = "user";
                    };
                };
            };

            config = {
                services.opencloud = {
                    enable = true;
                    # The six-monthly production line, not the three-weekly rolling one. OpenCloud can't
                    # be downgraded, so switching to pkgs.opencloud is one way.
                    package = pkgs.opencloud-production;
                    inherit url;
                    environment = {
                        # Cloudflare and Caddy (caddy.nix) handle TLS; OpenCloud serves plain HTTP on localhost.
                        OC_INSECURE = "true";
                        PROXY_TLS = "false";
                        # Komodo Core has 9120 (komodo/core.nix).
                        GRAPH_HTTP_ADDR = "127.0.0.1:9123";

                        OC_OIDC_ISSUER = idp;
                        OC_EXCLUDE_RUN_SERVICES = "idp";
                        # Apps that ask OpenCloud where to log in get Pocket ID.
                        PROXY_OIDC_REWRITE_WELLKNOWN = "true";
                        # Each token is still checked against Pocket ID's userinfo endpoint (cached).
                        PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
                        # Accounts are made on first login; the username is Pocket ID's.
                        PROXY_AUTOPROVISION_ACCOUNTS = "true";
                        PROXY_USER_OIDC_CLAIM = "preferred_username";
                        PROXY_USER_CS3_CLAIM = "username";
                        PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
                        GRAPH_ASSIGN_DEFAULT_USER_ROLE = "false";
                        PROXY_CSP_CONFIG_FILE_LOCATION = "${csp}";
                    };
                };

                # Without the disk OpenCloud would start empty on the root filesystem.
                systemd.services.opencloud.unitConfig.RequiresMountsFor = [ stateDir ];

                homelab.pocketId = {
                    groups = lib.mapAttrs' (
                        role: claim:
                        lib.nameValuePair (group role) {
                            friendlyName = "OpenCloud ${role}s";
                            claims.roles = claim;
                            members = lib.attrNames (lib.filterAttrs (_: r: r == role) cfg.users);
                        }
                    ) roles;
                    # The client IDs OpenCloud's apps have built in, with their redirects.
                    clients = {
                        web = {
                            groups = allowed;
                            name = "OpenCloud";
                            callbackURLs = [
                                "${url}/"
                                "${url}/oidc-callback.html"
                                "${url}/oidc-silent-redirect.html"
                            ];
                            logoutCallbackURLs = [ "${url}/" ];
                            launchURL = url;
                        };
                        # Any port on loopback matches.
                        OpenCloudDesktop = {
                            groups = allowed;
                            name = "OpenCloud Desktop";
                            callbackURLs = [
                                "http://127.0.0.1"
                                "http://localhost"
                            ];
                        };
                        OpenCloudAndroid = {
                            groups = allowed;
                            name = "OpenCloud Android";
                            callbackURLs = [ "oc://android.opencloud.eu" ];
                            logoutCallbackURLs = [ "oc://android.opencloud.eu" ];
                        };
                        OpenCloudIOS = {
                            groups = allowed;
                            name = "OpenCloud iOS";
                            callbackURLs = [ "oc://ios.opencloud.eu" ];
                            logoutCallbackURLs = [ "oc://ios.opencloud.eu" ];
                        };
                    };
                };

                services.caddy.virtualHosts."http://${cfg.domain}".extraConfig = ''
                    reverse_proxy 127.0.0.1:${toString port}
                '';

                # The files, OpenCloud's own state, and the secrets `opencloud init` wrote on first start
                # (/etc/opencloud/opencloud.yaml); a restore needs all three. The search index and
                # thumbnails are rebuilt by OpenCloud.
                homelab.backup = {
                    paths = [
                        stateDir
                        "/etc/opencloud"
                    ];
                    exclude = [
                        "${stateDir}/search"
                        "${stateDir}/thumbnails"
                    ];
                };
            };
        };
}
