{ inputs, ... }:

# sops-nix: secrets are committed encrypted (secrets/*.yaml, recipients in .sops.yaml) and
# decrypted at activation into /run/secrets, never into the Nix store. Features declare the
# secrets they need next to their own config (sops.secrets.<name>, sops.templates.<name>).
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
                # Each host decrypts with an age key derived from its own SSH host key, which
                # openssh (openssh.nix) creates on first boot. No key file to copy around.
                age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                gnupg.sshKeyPaths = [ ];
            };
        };

    flake.modules.homeManager.common =
        { config, pkgs, ... }:
        {
            imports = [ inputs.sops-nix.homeManagerModules.sops ];

            # User-level secrets (secrets/home.yaml) use their own age key: the host key is
            # root-only. Put the private key here from Bitwarden before declaring any.
            sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

            # sops edits the files; ssh-to-age turns a host's SSH key into its age recipient.
            home.packages = with pkgs; [
                sops
                ssh-to-age
                age
            ];
        };
}
