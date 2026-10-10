_:

{
  # Shell integrations. Their init code goes into hm-init.zsh (see zsh.nix).
  # starship reads its config from dotfiles/starship.toml.
  programs = {
    direnv.enable = true;
    zoxide.enable = true;
    starship.enable = true;
    fzf.enable = true;
  };
}
