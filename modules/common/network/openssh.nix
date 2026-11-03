{ config, lib, ... }:

let
    inherit (config) vars;

    hosts = lib.attrNames config.flake.nixosConfigurations;
in
{

    flake.modules.nixos.common =
        { pkgs, ... }:
        {

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

            programs.ssh.extraConfig = lib.concatMapStrings (host: ''
                Host ${lib.removePrefix "kash-" host}
                    HostName ${host}
            '') hosts;
        };
}
