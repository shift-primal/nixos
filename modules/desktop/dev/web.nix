{ config, inputs, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.homeManager.desktop =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        {
            # oxfmt and oxlint config.
            dotfiles.links.oxc = "oxc";

            # oxfmt finds its config by searching up from cwd, so this gives the CLI the same
            # fallback nvim passes with -c (conform.lua skips it when looking for a project config)
            home.file.".oxfmtrc.json".source =
                config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/oxc/oxfmtrc.json";

            programs.zsh.sessionVariables.npm_config_manage_package_manager_versions = "false";

            home.packages = with pkgs; [
                nodejs
                pnpm
                sassc

                node-gyp
                gnumake

                # lsp / formatters
                oxfmt
                oxlint
                biome
                typescript
                astro-language-server
                tailwindcss-language-server
                inputs.nix-vite-plus.packages.${pkgs.stdenv.hostPlatform.system}.vp

                # dependencies
                vscode-js-debug
                (writeShellScriptBin "js-debug-adapter" ''
                    exec ${lib.getExe vscode-js-debug} "$@"
                '')
            ];
        };
}
