_:

{
    # HTTPS for the Tailscale-only apps: tailscaled serves https://<host>.<tailnet>.ts.net:<port> with
    # a Let's Encrypt certificate it fetches itself and proxies to the app on 127.0.0.1:<port>. On the
    # tailnet it takes the port over from the app's plain HTTP (it answers before the kernel does).
    # Needs MagicDNS and HTTPS Certificates turned on once in the Tailscale admin console (DNS page).
    # The .local names stay plain HTTP: no public CA signs them (local-names.nix). Features add
    # their ports to homelab.tailscaleHttps.
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

            # The serve config lives in tailscaled's state; resetting it first drops ports no feature
            # lists any more. Not a oneshot: a switch waits for a oneshot to finish, and `tailscale
            # serve` waits as long as HTTPS is off in the admin console, so it would hang the switch.
            # As a plain service it runs alongside, gives up after a minute and retries.
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
