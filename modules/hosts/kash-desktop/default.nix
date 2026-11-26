{
    aspects,
    inputs,
    vars,
    ...
}:

{
    flake.nixosConfigurations.kash-desktop = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs vars; };
        modules = with aspects; [
            system
            hardware
            desktop
            shell
            dev
            apps

            nvidia

            ./_hardware-configuration.nix
            ./_machine.nix
        ];
    };
}
