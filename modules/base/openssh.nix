{ config, lib, ... }:

let
    inherit (config) vars;
in
{
    # SSH in with any key from vars.user.sshKeys (modules/flake/vars.nix), only over Tailscale (tailscale.nix).
    flake.modules.nixos.base =
        { pkgs, ... }:
        {
            # SSH from kitty sends TERM=xterm-kitty; without its terminfo zsh's line editor garbles input.
            environment.systemPackages = [ pkgs.kitty.terminfo ];

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

            users.users.${vars.user.name}.openssh.authorizedKeys.keys = lib.attrValues vars.user.sshKeys;
        };
}
