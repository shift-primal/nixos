{
    inputs,
    lib,
    pkgs,
    ...
}:

{
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
        vtsls
        tailwindcss-language-server
        vue-language-server
        inputs.nix-vite-plus.packages.${pkgs.stdenv.hostPlatform.system}.vp

        # dependencies
        vscode-js-debug
        (writeShellScriptBin "js-debug-adapter" ''
            exec ${lib.getExe vscode-js-debug} "$@"
        '')
    ];
}
