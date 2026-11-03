{
    description = "NixOS system and Home Manager config";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        flake-parts = {
            url = "github:hercules-ci/flake-parts";
            inputs.nixpkgs-lib.follows = "nixpkgs";
        };

        import-tree.url = "github:vic/import-tree";

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
    };

    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
