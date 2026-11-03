{ config, inputs, ... }:

let
    hostname = "kash-desktop";
    nixos = config.flake.modules.nixos;
in
{

    flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
        modules = [ nixos.${hostname} ];
    };

    flake.modules.nixos.${hostname} = {
        imports = [
            nixos.common
            nixos.desktop
            ./_hardware-configuration.nix
        ];

        networking.hostName = hostname;

        system.stateVersion = "26.05";
    };
}
