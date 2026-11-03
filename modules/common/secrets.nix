{ inputs, ... }:

{
    flake.modules.nixos.common =
        { config, lib, ... }:
        let
            hostFile = ../../secrets/hosts/${config.networking.hostName}.yaml;
        in
        {
            imports = [ inputs.sops-nix.nixosModules.sops ];

            sops = {
                defaultSopsFile = lib.mkIf (builtins.pathExists hostFile) hostFile;

                age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                gnupg.sshKeyPaths = [ ];
            };
        };

    flake.modules.homeManager.common =
        { config, pkgs, ... }:
        {
            imports = [ inputs.sops-nix.homeManagerModules.sops ];

            sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

            home.packages = with pkgs; [
                sops
                ssh-to-age
                age
            ];
        };
}
