{
    flake.modules.nixos.noctalia =
        {
            config,
            inputs,
            link,
            vars,
            ...
        }:
        let
            inherit (config.networking) hostName;
        in
        {
            services.displayManager.noctalia-greeter = {
                enable = true;
                settings = {
                    session.default = "Hyprland";
                    keyboard.layout = vars.keyboard.layout;
                    cursor.size = vars.cursor.size;
                };
            };

            hm = {
                imports = [ inputs.noctalia.homeModules.default ];

                programs.noctalia.enable = true;

                xdg.configFile = {
                    "noctalia/config.toml".source = link "noctalia/config.toml";
                    "noctalia/host.toml".source = link "noctalia/hosts/${hostName}.toml";
                };

                xdg.stateFile."noctalia/settings.toml" = {
                    source = link "noctalia/settings/${hostName}.toml";
                    force = true;
                };
            };
        };
}
