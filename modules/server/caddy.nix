_:

{
    # Reverse proxy for every web service on the host. Each feature adds its own
    # services.caddy.virtualHosts entry (komodo/core.nix); Caddy gets certificates itself.
    flake.modules.nixos.caddy = {
        services.caddy.enable = true;
        networking.firewall.allowedTCPPorts = [
            80
            443
        ];
    };
}
