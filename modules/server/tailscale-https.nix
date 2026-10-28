_:

{
    # HTTPS for the Tailscale-only apps: tailscaled serves https://<host>.<tailnet>.ts.net:<port> with
    # a Let's Encrypt certificate it fetches itself and proxies to the app on 127.0.0.1:<port>. On the
    # tailnet it takes the port over from the app's plain HTTP (it answers before the kernel does).
    # Needs MagicDNS and HTTPS Certificates turned on once in the Tailscale admin console (DNS page).
    # The .local names stay plain HTTP: no public CA signs them (local-names.nix). Features add
    # ports: media/arr.nix, media/bazarr.nix, media/decypharr.nix.
    flake.modules.nixos.caddy =
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
            options.homelab.tailscaleHttps = lib.mkOption {
                type = with lib.types; listOf port;
                default = [ ];
                description = "Ports on 127.0.0.1 to serve as HTTPS on the same port of the host's ts.net name.";
            };

            # The serve config lives in tailscaled's state; resetting it first drops ports no feature
            # lists any more.
            config.systemd.services.tailscale-https = lib.mkIf (ports != [ ]) {
                description = "Serve the Tailscale-only apps over HTTPS";
                wantedBy = [ "multi-user.target" ];
                after = [ "tailscaled.service" ];
                requires = [ "tailscaled.service" ];
                path = [ pkgs.jq ];
                script = ''
                    until ${tailscale} status --json | jq -e '.BackendState == "Running"' > /dev/null; do
                        sleep 2
                    done
                    ${tailscale} serve reset
                    ${lib.concatMapStrings (port: ''
                        ${tailscale} serve --bg --https=${toString port} http://127.0.0.1:${toString port}
                    '') ports}
                '';
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    TimeoutStartSec = 300;
                };
            };
        };
}
