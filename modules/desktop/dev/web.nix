{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.homeManager.desktop =
        { config, ... }:
        {
            dotfiles.links.oxc = "oxc";
            home.file.".oxfmtrc.json".source =
                config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/oxc/oxfmtrc.json";

            programs.zsh.sessionVariables.npm_config_manage_package_manager_versions = "false";
        };
}
