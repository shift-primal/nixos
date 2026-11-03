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
            ports = config.homelab.tailscaleHttps;
            tailscale = lib.getExe config.services.tailscale.package;
        in
        {
            options.homelab.tailnet = lib.mkOption {
                type = lib.types.str;
                example = "tail1234.ts.net";
                description = "The tailnet's MagicDNS domain, for links to the ports served here.";
            };

            options.homelab.tailscaleHttps = lib.mkOption {
                type = with lib.types; listOf port;
                default = [ ];
                description = "Ports on 127.0.0.1 to serve as HTTPS on the same port of the host's ts.net name.";
            };

            config.systemd.services.tailscale-https = lib.mkIf (ports != [ ]) {
                description = "Serve the Tailscale-only apps over HTTPS";
                wantedBy = [ "multi-user.target" ];
                after = [ "tailscaled.service" ];
                requires = [ "tailscaled.service" ];
                path = with pkgs; [
                    jq
                    coreutils
                ];
                script = ''
                    until ${tailscale} status --json | jq -e '.BackendState == "Running"' > /dev/null; do
                        sleep 2
                    done
                    ${tailscale} serve reset
                    ${lib.concatMapStrings (port: ''
                        timeout 60 ${tailscale} serve --bg --https=${toString port} http://127.0.0.1:${toString port}
                    '') ports}
                '';
                serviceConfig = {
                    RemainAfterExit = true;
                    Restart = "on-failure";
                    RestartSec = 60;
                };
            };
        };
}
