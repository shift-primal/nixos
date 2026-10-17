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
        # Loads after config.toml, so it only holds what differs on this machine.
        "noctalia/host.toml" = "noctalia/hosts/${vars.hostname}.toml";
        "nvim" = "nvim";
        # Fallback oxfmt/oxlint config for projects without their own (see nvim config/ox.lua).
        "oxc" = "oxc";
        "starship.toml" = "starship.toml";
        "zsh/.zshrc" = "zsh/.zshrc";
    };
in
{
    xdg.configFile = lib.mapAttrs (_: source: { source = link source; }) links;

    # Noctalia writes anything it saves to settings.toml (loaded last) and follows symlinks, so
    # pointing it at the repo keeps GUI changes visible in git. One file per host, so changes made
    # in the GUI on one machine don't carry over to the other.
    xdg.stateFile."noctalia/settings.toml" = {
        source = link "noctalia/settings/${vars.hostname}.toml";
        force = true;
    };
}
