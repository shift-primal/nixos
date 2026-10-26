_:

{
    # Short names for the TVs and phones at home: the homelab announces them over mDNS (Bonjour),
    # which Apple devices, Android, Windows and Linux all resolve without any setup, and Caddy
    # (caddy.nix) routes them on port 80 so nobody has to type a port.
    flake.modules.nixos.media =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            # Name on the home LAN → local port. Plain HTTP: no certificate covers a .local name.
            jellyfin = "snyltflix.local";
            names = {
                ${jellyfin} = 8096; # jellyfin.nix
                "req.local" = config.services.seerr.port;
            };
        in
        {
            options.homelab.media.jellyfinUrl = lib.mkOption {
                type = lib.types.str;
                default = "http://${jellyfin}";
                readOnly = true;
                description = "Jellyfin's address on the home LAN, for links to it (configure.nix).";
            };

            config.services.avahi = {
                enable = true;
                settings.publish = {
                    disable-publishing = false;
                    publish-addresses = true;
                };
            };

            # avahi-publish needs the address itself; read it from the default route at start, so a
            # new DHCP lease only needs a restart (it also restarts on every boot).
            config.systemd.services = lib.mapAttrs' (
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
            ) names;

            # Caddy binds to localhost for the tunnel; these two also listen on the LAN.
            config.services.caddy.virtualHosts = lib.mapAttrs' (
                name: port:
                lib.nameValuePair "http://${name}" {
                    listenAddresses = [ "0.0.0.0" ];
                    extraConfig = "reverse_proxy 127.0.0.1:${toString port}";
                }
            ) names;
            config.networking.firewall.allowedTCPPorts = [ 80 ];
        };
}
