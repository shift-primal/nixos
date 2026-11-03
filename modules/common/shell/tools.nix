_:

{
    flake.modules.homeManager.common = {

        programs = {

            direnv = {
                enable = true;
                nix-direnv.enable = true;

                config.global.hide_env_diff = true;
            };
            zoxide.enable = true;
            starship.enable = true;
            fzf.enable = true;
        };
    };
}
