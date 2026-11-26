{
    flake.modules.nixos.languages =
        { pkgs, link, ... }:
        {
            hm = {
                home.packages = with pkgs; [
                    python3
                    uv
                    ruff
                    sqlfluff

                    go
                    gopls

                    rustc
                    cargo
                    rust-analyzer
                    clippy
                    rustfmt

                    clang-tools

                    hadolint
                    shfmt
                    markdownlint-cli2
                ];

                xdg.configFile."ruff".source = link "ruff";
            };
        };
}
