_:

{
    # HTTP proxy so kasper-vps can send traffic out through this machine's connection.
    flake.modules.nixos.kash-desktop-nixos = {
        services.tinyproxy = {
            enable = true;
            settings = {
                Listen = null; # every interface; the firewall only opens it on Tailscale
                Port = 8888;
                Allow = [ "100.104.161.15" ]; # kasper-vps on Tailscale
            };
        };
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8888 ];
    };
}
