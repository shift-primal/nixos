{
    description = "Node.js dev shell";

    inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

    outputs =
        { self, ... }@inputs:

        let
            supportedSystems = [
                "x86_64-linux"
                "aarch64-linux"
                "aarch64-darwin"
            ];
            forEachSupportedSystem =
                f:
                inputs.nixpkgs.lib.genAttrs supportedSystems (
                    system:
                    f {
                        inherit system;
                        pkgs = import inputs.nixpkgs {
                            inherit system;
                            overlays = [ inputs.self.overlays.default ];
                        };
                    }
                );
        in
        {
            overlays.default = final: prev: {
                nodejs = prev.nodejs_24;
            };

            devShells = forEachSupportedSystem (
                { pkgs, system }:
                {
                    default = pkgs.mkShellNoCC {
                        packages = with pkgs; [
                            nodejs
                            pnpm
                            self.formatter.${system}
                        ];
                    };
                }
            );

            formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
        };
}
