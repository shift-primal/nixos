_:

{
    flake.modules.homeManager.common = {
        # Shell integrations. Their init code goes into hm-init.zsh (see zsh.nix).
        # starship reads its config from dotfiles/starship.toml.
        programs = {
            # nix-direnv caches each project's dev shell and keeps it from being garbage collected.
            direnv = {
                enable = true;
                nix-direnv.enable = true;
                # Keeps the "loading" and "using flake" lines but drops the long "export +AR +AS ..." list.
                config.global.hide_env_diff = true;
            };
            zoxide.enable = true;
            starship.enable = true;
            fzf.enable = true;
        };
    };
}
