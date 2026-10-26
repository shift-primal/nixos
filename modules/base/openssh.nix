{ config, ... }:

let
    inherit (config) vars;
in
{
    # SSH in with the personal key from modules/flake/vars.nix, only over Tailscale (tailscale.nix).
    flake.modules.nixos.base = {
        services.openssh = {
            enable = true;
            openFirewall = false;
            settings = {
                PasswordAuthentication = false;
                KbdInteractiveAuthentication = false;
                PermitRootLogin = "no";
            };
        };
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

        users.users.${vars.user.name}.openssh.authorizedKeys.keys = [ vars.user.sshKey ];
    };
}
