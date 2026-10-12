# Linked to ~/.config/zsh/.zshrc from ~/nixos/dotfiles.
# Edits here apply on the next shell. Do not hand-edit the generated file.
#
# Home Manager writes plugin and integration setup to hm-init.zsh
# (Oh My Zsh, autosuggestions, syntax highlighting, zoxide, fzf, direnv,
# starship, history, and PATH). That file uses Nix store paths and is
# replaced on nixos-rebuild. Environment variables live in
# ~/nixos/home/shell/zsh.nix so they are set before this file runs.

hm_init="${ZDOTDIR:-$HOME/.config/zsh}/hm-init.zsh"
if [[ -r $hm_init ]]; then
  source "$hm_init"
fi

# Vite+ shims on PATH plus the `vp` function `vp env use` needs. After hm-init so compdef exists.
vp_env="$HOME/.config/vite-plus/env"
if [[ -r $vp_env ]]; then
  source "$vp_env"
fi

alias nvimcfg='cd ~/.config/nvim && nvim .'
alias py='python'
alias ff='fastfetch'
alias ls='eza'
alias rb:switch='sudo rebuild switch'
alias rb:boot='sudo rebuild boot'
