_:

{
    # Per-project dev shells: `nix flake init -t ~/nixos#<name>`, then `direnv allow`. The env
    # loads on cd (nix-direnv, modules/common/shell/tools.nix). Project toolchains and their
    # LSPs live here, not in modules/desktop/dev/.
    flake.templates = {
        node = {
            path = ../../templates/node;
            description = "Node.js: nodejs, pnpm, typescript, oxfmt, oxlint, biome, vite-plus";
        };
        python = {
            path = ../../templates/python;
            description = "Python: python3, uv, pyright, ruff, debugpy";
        };
        rust = {
            path = ../../templates/rust;
            description = "Rust: rustc, cargo, rustfmt, clippy, rust-analyzer";
        };
        go = {
            path = ../../templates/go;
            description = "Go: go, gopls";
        };
        c = {
            path = ../../templates/c;
            description = "C/C++: gcc, clangd";
        };
        dotnet = {
            path = ../../templates/dotnet;
            description = ".NET: SDK 8/9/10, omnisharp, fsautocomplete, csharpier, fantomas, netcoredbg";
        };
    };
}
