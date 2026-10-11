{ lib, pkgs, ... }:

{
    # Set on zsh, not home.sessionVariables: that one is sourced once per login, so a rebuild never
    # reaches open sessions. A project's "packageManager" field makes pnpm download that exact version, a generic-linux
    # binary that NixOS can't run. Keep the Nix-installed pnpm instead.
    programs.zsh.sessionVariables.npm_config_manage_package_manager_versions = "false";

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
