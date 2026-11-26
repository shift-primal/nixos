{
    aspects,
    inputs,
    vars,
    ...
}:

{
    flake.nixosConfigurations.kash-laptop = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs vars; };
        modules = with aspects; [
            system
            hardware
            desktop
            shell
            dev
            apps

            intel-graphics
            autologin

            ./_hardware-configuration.nix
            ./_machine.nix
        ];
    };
}
