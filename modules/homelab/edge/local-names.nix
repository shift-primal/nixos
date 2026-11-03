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
            names = config.homelab.localNames;
            mdnsNames = lib.filterAttrs (name: _: lib.hasSuffix ".local" name) names;
        in
        {
            options.homelab.localNames = lib.mkOption {
                type = with lib.types; attrsOf port;
                default = { };
                description = "Name on the home LAN or tailnet → port on 127.0.0.1. Plain HTTP: no certificate covers these names.";
            };

            config = lib.mkIf (names != { }) {
                services.avahi = lib.mkIf (mdnsNames != { }) {
                    enable = true;
                    settings.publish = {
                        disable-publishing = false;
                        publish-addresses = true;

                        disable-user-service-publishing = false;
                    };
                };

                systemd.services = lib.mapAttrs' (
                    name: _:
                    lib.nameValuePair "mdns-${lib.removeSuffix ".local" name}" {
                        description = "Announce ${name} over mDNS";
                        wantedBy = [ "multi-user.target" ];
                        after = [
                            "avahi-daemon.service"
                            "network-online.target"
                        ];
                        wants = [ "network-online.target" ];
                        requires = [ "avahi-daemon.service" ];
                        path = with pkgs; [
                            avahi
                            iproute2
                            gnugrep
                        ];
                        script = ''
                            ip=$(ip -4 route get 1.1.1.1 | grep -oP 'src \K\S+')
                            exec avahi-publish --address --no-reverse ${name} "$ip"
                        '';
                        serviceConfig = {
                            Restart = "always";
                            RestartSec = 10;
                        };
                    }
                ) mdnsNames;

                services.caddy.virtualHosts = lib.mapAttrs' (
                    name: port:
                    lib.nameValuePair "http://${name}" {
                        listenAddresses = [ "0.0.0.0" ];
                        extraConfig = "reverse_proxy 127.0.0.1:${toString port}";
                    }
                ) names;

                networking.firewall = {
                    allowedTCPPorts = [ 80 ];
                    extraCommands = ''
                        iptables -w -I nixos-fw -p tcp --dport 443 -j REJECT --reject-with tcp-reset
                        ip6tables -w -I nixos-fw -p tcp --dport 443 -j REJECT --reject-with tcp-reset
                    '';
                };
            };
        };
}
