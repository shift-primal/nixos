{
    description = "Python dev shell";

    inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    outputs =
        { nixpkgs, ... }:
        let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
            devShells.x86_64-linux.default = pkgs.mkShell {
                packages = with pkgs; [
                    python3
                    uv
                    pyright
                    ruff
                    python3Packages.debugpy
                ];
            };
        };
}
