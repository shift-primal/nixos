{ config, ... }:

let
    inherit (config) vars;
in
{

    flake.modules.homeManager.common =
        { config, lib, ... }:
        let
            link = path: config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/${path}";
        in
        {
            options.dotfiles.links = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "Links from ~/.config/<name> to dotfiles/<path> in the flake.";
            };

            config = {
                xdg.configFile = lib.mapAttrs (_: source: { source = link source; }) config.dotfiles.links;

                dotfiles.links = {
                    "starship.toml" = "starship.toml";
                    "zsh/.zshrc" = "zsh/.zshrc";
                };
            };
        };
}
