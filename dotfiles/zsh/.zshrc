# Linked to ~/.config/zsh/.zshrc from ~/nixos/dotfiles.
# Edits here apply on the next shell. Do not hand-edit the generated file.
#
# Home Manager writes plugin and integration setup to hm-init.zsh
# (Oh My Zsh, autosuggestions, syntax highlighting, zoxide, fzf, direnv,
# starship, history, and PATH). That file uses Nix store paths and is
# replaced on nixos-rebuild. Environment variables live in
# ~/nixos/modules/common/shell/zsh.nix so they are set before this file runs.

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

# Pull and switch the homelab from here; rebuild.nix lets sudo run without a password, so no tty.
# Streams the build, then ends with a clear verdict; on failure repeats the log's end and keeps the file.
homelab:switch() {
  local log
  log=$(mktemp -t homelab-switch.XXXXXX)
  ssh homelab 'git -C /etc/nixos pull --ff-only && sudo rebuild switch' 2>&1 | tee "$log"
  if (( pipestatus[1] == 0 )); then
    print -P "%F{green}homelab: switched%f"
    rm -f "$log"
  else
    print -P "\n%F{red}homelab: failed%f, full log in $log"
    tail -n 40 "$log"
    return 1
  fi
}
