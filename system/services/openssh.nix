{ vars, ... }:

# SSH in with the personal key from vars.nix, only over Tailscale (system/services/tailscale.nix).
{
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
}
