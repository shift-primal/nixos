{
    flake.modules.nixos.shell-plugins =
        { link, ... }:
        {
            hm = {
                programs = {
                    direnv = {
                        enable = true;
                        nix-direnv.enable = true;
                        config.global.hide_env_diff = true;
                    };
                    zoxide.enable = true;
                    starship.enable = true;
                    fzf.enable = true;

                    zsh.sessionVariables._ZO_DOCTOR = "0";
                };

                xdg.configFile."starship.toml".source = link "starship.toml";
            };
        };
}
