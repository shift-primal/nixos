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

        sops-nix = {
            url = "github:Mic92/sops-nix";
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

    # Every .nix file under modules/ is a flake-parts module, imported automatically.
    # Paths containing /_ are skipped (hardware-configuration.nix files).
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
