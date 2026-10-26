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

    # HP ProDesk 400 G3 SFF. The other files in this folder (boot) add to this module too.
    flake.modules.nixos.${hostname} = {
        # _hardware-configuration.nix is a placeholder until the machine is installed. Replace it with:
        #   nixos-generate-config --show-hardware-config > _hardware-configuration.nix
        imports = [
            nixos.base
            nixos.komodo
            nixos.caddy
            ./_hardware-configuration.nix
        ];

        networking.hostName = hostname;

        # Placeholder: point a DNS record at this machine, then set the real name.
        homelab.komodo.domain = "komodo.example.com";

        # Release this machine was first installed with. Do not bump on upgrades.
        # Must match system.stateVersion in the installer's /etc/nixos/configuration.nix.
        system.stateVersion = "26.05";
    };
}
