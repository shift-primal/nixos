{
    description = "NixOS config for kash-desktop and kash-laptop";

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

        llm-agents = {
            url = "github:numtide/llm-agents.nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        ai-usagebar = {
            url = "github:akitaonrails/ai-usagebar";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        grimoire = {
            url = "github:Slush97/grimoire";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs =
        { nixpkgs, ... }@inputs:
        let
            vars = import ./vars.nix;
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            host =
                hostName:
                nixpkgs.lib.nixosSystem {
                    specialArgs = { inherit inputs vars; };
                    modules = [ ./hosts/${hostName} ];
                };
        in
        {
            nixosConfigurations = nixpkgs.lib.genAttrs [ "kash-desktop" "kash-laptop" ] host;

            overlays.default = import ./pkgs;

            formatter.x86_64-linux = pkgs.writeShellApplication {
                name = "treefmt";
                runtimeInputs = [
                    pkgs.treefmt
                    (pkgs.callPackage ./pkgs/nixfmt.nix { })
                ];
                text = ''exec treefmt "$@"'';
            };
        };
}
