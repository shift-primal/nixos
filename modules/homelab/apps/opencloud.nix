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
            cfg = config.homelab.drive;
            inherit (config.services.opencloud) stateDir port;
            url = "https://${cfg.domain}";
            idp = "https://${config.homelab.pocketId.domain}";

            roles = {
                admin = "opencloudAdmin";
                user = "opencloudUser";
            };
            group = role: "opencloud-${role}s";

            allowed = map group (lib.attrNames roles);

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

                    package = pkgs.opencloud-production;
                    inherit url;
                    environment = {

                        OC_INSECURE = "true";
                        PROXY_TLS = "false";

                        GRAPH_HTTP_ADDR = "127.0.0.1:9123";

                        OC_OIDC_ISSUER = idp;
                        OC_EXCLUDE_RUN_SERVICES = "idp";

                        PROXY_OIDC_REWRITE_WELLKNOWN = "true";

                        PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";

                        PROXY_AUTOPROVISION_ACCOUNTS = "true";
                        PROXY_USER_OIDC_CLAIM = "preferred_username";
                        PROXY_USER_CS3_CLAIM = "username";
                        PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
                        GRAPH_ASSIGN_DEFAULT_USER_ROLE = "false";
                        PROXY_CSP_CONFIG_FILE_LOCATION = "${csp}";
                    };
                };

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
