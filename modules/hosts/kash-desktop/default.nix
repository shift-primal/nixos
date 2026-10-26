{ config, inputs, ... }:

let
    hostname = "kash-desktop";
    nixos = config.flake.modules.nixos;
in
{
    # Named after the hostname, so `nixos-rebuild switch --flake ~/nixos` picks it.
    flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
        modules = [ nixos.${hostname} ];
    };

    # The other files in this folder (boot, NVIDIA) add to this module too.
    flake.modules.nixos.${hostname} = {
        imports = [
            nixos.base
            nixos.workstation
            nixos.dev
            ./_hardware-configuration.nix
        ];

        networking.hostName = hostname;

        # Release this machine was first installed with. Do not bump on upgrades.
        system.stateVersion = "26.05";
    };
}
