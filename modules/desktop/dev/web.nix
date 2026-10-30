{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.homeManager.desktop =
        { config, ... }:
        {
            # oxfmt and oxlint config. The tools themselves come from each project's dev shell
            # (templates/node).
            dotfiles.links.oxc = "oxc";

            # oxfmt finds its config by searching up from cwd, so this gives the CLI the same
            # fallback nvim passes with -c (conform.lua skips it when looking for a project config)
            home.file.".oxfmtrc.json".source =
                config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/oxc/oxfmtrc.json";

            programs.zsh.sessionVariables.npm_config_manage_package_manager_versions = "false";
        };
}
