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

            templates = {
                node = {
                    path = ./templates/node;
                    description = "Node.js: nodejs, pnpm, typescript, oxfmt, oxlint, biome, vite-plus";
                };
                python = {
                    path = ./templates/python;
                    description = "Python: python3, uv, pyright, ruff, debugpy";
                };
                rust = {
                    path = ./templates/rust;
                    description = "Rust: rustc, cargo, rustfmt, clippy, rust-analyzer";
                };
                go = {
                    path = ./templates/go;
                    description = "Go: go, gopls";
                };
                c = {
                    path = ./templates/c;
                    description = "C/C++: gcc, clangd";
                };
                dotnet = {
                    path = ./templates/dotnet;
                    description = ".NET: SDK 8/9/10, omnisharp, fsautocomplete, csharpier, fantomas, netcoredbg";
                };
            };

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
