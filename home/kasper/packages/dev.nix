{ pkgs, ... }:

{
  # LazyVim extras expect these on PATH. Mason's prebuilt binaries use
  # /lib64/ld-linux and do not run under NixOS stub-ld.
  home.packages = with pkgs; [
    (python3.withPackages (ps: [ ps.debugpy ]))
    gcc
    tree-sitter
    cargo
    rustc
    rustfmt
    clippy
    nodejs
    pnpm
    biome
    sassc
    go
    dotnet-sdk

    lua-language-server
    stylua

    nil
    nixfmt
    statix

    pyright
    ruff
    black

    dockerfile-language-server
    docker-compose-language-service
    hadolint

    omnisharp-roslyn
    fsautocomplete
    csharpier
    fantomas
    netcoredbg

    vtsls
    vue-language-server
    vscode-js-debug
    # LazyVim's TypeScript extra looks up this name. The Nix package ships js-debug.
    (writeShellScriptBin "js-debug-adapter" ''
      exec ${pkgs.lib.getExe vscode-js-debug} "$@"
    '')

    tailwindcss-language-server
    sqlfluff
    shfmt
  ];
}
