_:

{
    # Short names for the TVs, phones and laptops at home: names ending in .local are announced over
    # mDNS (Bonjour), which Apple devices, Android, Windows and Linux all resolve without any setup.
    # Caddy routes every name on port 80 of all interfaces, so nobody has to type a port; that also
    # covers the host's Tailscale MagicDNS name. Features add names: media/local-names.nix,
    # komodo/apps.nix (an app's `localNames`).
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
                        # Lets the mdns-* services below (avahi-publish) register names; off, Avahi refuses them.
                        disable-user-service-publishing = false;
                    };
                };

                # avahi-publish needs the address itself; read it from the default route at start, so a
                # new DHCP lease only needs a restart (it also restarts on every boot).
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

                # Caddy binds to localhost for the tunnel (caddy.nix); these also listen on the LAN.
                services.caddy.virtualHosts = lib.mapAttrs' (
                    name: port:
                    lib.nameValuePair "http://${name}" {
                        listenAddresses = [ "0.0.0.0" ];
                        extraConfig = "reverse_proxy 127.0.0.1:${toString port}";
                    }
                ) names;
                # Safari on iOS tries https:// first when you type a bare name and only falls back to
                # http:// once that fails. The firewall drops packets by default, so the attempt would
                # hang until it times out; a TCP reset on 443 makes the fallback instant. Nothing
                # listens on 443 here. The chain is rebuilt on every firewall reload, so the rule needs
                # no cleanup.
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
