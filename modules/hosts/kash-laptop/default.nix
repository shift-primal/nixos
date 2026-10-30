{ config, inputs, ... }:

let
    hostname = "kash-laptop";
    nixos = config.flake.modules.nixos;
in
{
    # Named after the hostname, so `nixos-rebuild switch --flake ~/nixos` picks it.
    flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
        modules = [ nixos.${hostname} ];
    };

    # The other files in this folder (boot, greetd, Intel, keyring, plymouth) add to this module too.
    flake.modules.nixos.${hostname} = {
        # _hardware-configuration.nix is generated on the laptop itself, and holds the LUKS devices:
        #   nixos-generate-config --show-hardware-config > _hardware-configuration.nix
        imports = [
            nixos.common
            nixos.desktop
            ./_hardware-configuration.nix
        ];

        networking.hostName = hostname;

        # Release this machine was first installed with. Do not bump on upgrades.
        # Must match system.stateVersion in the installer's /etc/nixos/configuration.nix.
        system.stateVersion = "26.05";
    };
}
