{
    description = "NixOS system and Home Manager config";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        noctalia = {
            url = "github:noctalia-dev/noctalia";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nix-claude-code = {
            url = "github:ryoppippi/nix-claude-code";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs =
        { nixpkgs, ... }@inputs:
        let
            vars = import ./vars.nix;
        in
        {
            # Named after the hostname so `nixos-rebuild switch --flake ~/nixos` picks it.
            nixosConfigurations.${vars.hostname} = nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs vars; };
                modules = [ ./hosts/${vars.hostname} ];
            };
        };
}
