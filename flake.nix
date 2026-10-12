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

        nix-vite-plus = {
            url = "github:ryoppippi/nix-vite-plus";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs =
        { nixpkgs, ... }@inputs:
        let
            inherit (nixpkgs) lib;

            # One nixosConfiguration per folder in hosts/, named after it, so
            # `nixos-rebuild switch --flake ~/nixos` picks the one matching the hostname.
            mkHost =
                hostname:
                let
                    vars = import ./vars.nix // import ./hosts/${hostname}/vars.nix // { inherit hostname; };
                in
                lib.nixosSystem {
                    specialArgs = { inherit inputs vars; };
                    modules = [ ./hosts/${hostname} ];
                };

            hosts = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts));
        in
        {
            nixosConfigurations = lib.genAttrs hosts mkHost;
        };
}
