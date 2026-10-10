{
    config,
    lib,
    vars,
    ...
}:

let
    # Links point into the repo, not the store, so edits apply without a rebuild.
    link = path: config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/${path}";

    # ~/.config/<target> = dotfiles/<source>
    links = {
        "hypr" = "hypr";
        "kitty" = "kitty";
        "nvim" = "nvim";
        "starship.toml" = "starship.toml";
        "zsh/.zshrc" = "zsh/.zshrc";
    };
in
{
    xdg.configFile = lib.mapAttrs (_: source: { source = link source; }) links;
}
