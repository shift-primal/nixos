{ config, inputs, ... }:

let
    hostname = "kash-homelab-nixos";
    nixos = config.flake.modules.nixos;
in
{
    # Named after the hostname, so `nixos-rebuild switch --flake ~/nixos` picks it.
    flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
        modules = [ nixos.${hostname} ];
    };

    # HP ProDesk 400 G3 SFF. The other files in this folder (boot, data) add to this module too.
    flake.modules.nixos.${hostname} = {
        # _hardware-configuration.nix is a placeholder until the machine is installed. Replace it with:
        #   nixos-generate-config --show-hardware-config > _hardware-configuration.nix
        # komodo and caddy come back once the host key is in .sops.yaml and
        # secrets/hosts/kash-homelab-nixos.yaml exists: komodo's secrets don't evaluate without it.
        imports = [
            nixos.base
            ./_hardware-configuration.nix
        ];

        networking.hostName = hostname;

        # Release this machine was first installed with. Do not bump on upgrades.
        # Must match system.stateVersion in the installer's /etc/nixos/configuration.nix.
        system.stateVersion = "26.05";
    };
}
