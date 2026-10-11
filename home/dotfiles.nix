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
        "noctalia/config.toml" = "noctalia/config.toml";
        "nvim" = "nvim";
        "starship.toml" = "starship.toml";
        "zsh/.zshrc" = "zsh/.zshrc";
    };
in
{
    xdg.configFile = lib.mapAttrs (_: source: { source = link source; }) links;

    # Noctalia writes anything it saves to settings.toml (loaded after config.toml) and follows
    # symlinks, so pointing it at the host file keeps those changes in the repo.
    xdg.stateFile."noctalia/settings.toml" = {
        source = link "noctalia/hosts/${vars.hostname}.toml";
        force = true;
    };
}
