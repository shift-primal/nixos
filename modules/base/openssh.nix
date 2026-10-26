{ config, lib, ... }:

let
    inherit (config) vars;
    # Every host in the flake, so a new machine gets its alias without editing this file.
    hosts = lib.attrNames config.flake.nixosConfigurations;
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

            # `ssh homelab` for kash-homelab, etc. The full name resolves through Tailscale MagicDNS.
            programs.ssh.extraConfig = lib.concatMapStrings (host: ''
                Host ${lib.removePrefix "kash-" host}
                    HostName ${host}
            '') hosts;
        };
}
