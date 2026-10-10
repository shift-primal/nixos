{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tree-sitter

    rustfmt
    clippy

    oxfmt
    oxlint
    biome
    vtsls
    tailwindcss-language-server
    vue-language-server
    vscode-js-debug
    (writeShellScriptBin "js-debug-adapter" ''
      	  exec ${pkgs.lib.getExe vscode-js-debug} "$@"
      	  '')

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

    sqlfluff

    shfmt

  ];
}
