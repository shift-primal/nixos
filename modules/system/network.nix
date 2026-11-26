{
    flake.modules.nixos.network = {
        networking.networkmanager.enable = true;

        services.tailscale.enable = true;
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    };
}
