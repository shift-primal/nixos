{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs
    pnpm
    sassc

    oxfmt
    oxlint
    biome
    vtsls
    tailwindcss-language-server
    vue-language-server

    vscode-js-debug
    # LazyVim's typescript extra starts the adapter as `js-debug-adapter`.
    (writeShellScriptBin "js-debug-adapter" ''
      exec ${lib.getExe vscode-js-debug} "$@"
    '')
  ];
}
