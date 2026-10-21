{
    config,
    lib,
    vars,
    ...
}:

let
    link = path: config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/${path}";

    links = {
        "hypr" = "hypr";
        "kitty" = "kitty";
        "noctalia/config.toml" = "noctalia/config.toml";
        "noctalia/host.toml" = "noctalia/hosts/${vars.hostname}.toml";
        "nvim" = "nvim";
        "oxc" = "oxc";
        "starship.toml" = "starship.toml";
        "zsh/.zshrc" = "zsh/.zshrc";
    };
in
{
    xdg.configFile = lib.mapAttrs (_: source: { source = link source; }) links;

    # Noctalia writes anything it saves to settings.toml. One file per host.
    xdg.stateFile."noctalia/settings.toml" = {
        source = link "noctalia/settings/${vars.hostname}.toml";
        force = true;
    };
}
