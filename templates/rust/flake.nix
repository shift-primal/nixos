{
    description = "Rust dev shell";

    inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    outputs =
        { nixpkgs, ... }:
        let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
            devShells.x86_64-linux.default = pkgs.mkShell {
                # nixpkgs' rustc has no std sources; rust-analyzer needs them.
                env.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

                packages = with pkgs; [
                    rustc
                    cargo
                    rustfmt
                    clippy
                    rust-analyzer
                ];
            };
        };
}
