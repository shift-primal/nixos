{ config, ... }:

let
    inherit (config) vars;
in
{
    # ~/.config/<name> -> dotfiles/<path>, linked out of the store so edits apply without a
    # rebuild. Each feature adds its own entries to dotfiles.links.
    flake.modules.homeManager.base =
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

                # .zshrc sources what Home Manager generates (shell/zsh.nix).
                dotfiles.links = {
                    "starship.toml" = "starship.toml";
                    "zsh/.zshrc" = "zsh/.zshrc";
                };
            };
        };
}
