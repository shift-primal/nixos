{
    description = "Node.js dev shell";

    inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    outputs =
        { nixpkgs, ... }:
        let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
            devShells.x86_64-linux.default = pkgs.mkShellNoCC {
                packages = with pkgs; [
                    nodejs_24
                    pnpm
                ];
            };
        };
}
