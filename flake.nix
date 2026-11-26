{
    description = "NixOS config for kash-desktop and kash-laptop";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        flake-parts = {
            url = "github:hercules-ci/flake-parts";
            inputs.nixpkgs-lib.follows = "nixpkgs";
        };

        import-tree.url = "github:vic/import-tree";

        antigravity-nix = {
            url = "github:jacopone/antigravity-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        noctalia = {
            url = "github:noctalia-dev/noctalia";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        luciole = {
            url = "github:noctalia-dev/luciole";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        llm-agents = {
            url = "github:numtide/llm-agents.nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        artcraft = {
            url = "github:ipeglin/artcraft-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
