{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.homeManager.desktop =
        { config, osConfig, ... }:
        let
            inherit (osConfig.networking) hostName;
        in
        {
            dotfiles.links = {
                "hypr" = "hypr";
                "kitty" = "kitty";
                "noctalia/config.toml" = "noctalia/config.toml";
                "noctalia/host.toml" = "noctalia/hosts/${hostName}.toml";
                "noctalia/palettes" = "noctalia/palettes";
            };

            xdg.stateFile."noctalia/settings.toml" = {
                source = config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/noctalia/settings/${hostName}.toml";
                force = true;
            };
        };
}
