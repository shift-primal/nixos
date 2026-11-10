# Linked to ~/.config/zsh/.zshrc from ~/nixos/dotfiles.
# Edits here apply on the next shell. Do not hand-edit the generated file.
#
# Home Manager writes plugin and integration setup to hm-init.zsh
# (Oh My Zsh, autosuggestions, syntax highlighting, zoxide, fzf, direnv,
# starship, history, and PATH). That file uses Nix store paths and is
# replaced on nixos-rebuild. Environment variables live in
# ~/nixos/home.nix so they are set before this file runs.

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

# dev <project> | dev new <name> <template> | dev init <template> | dev ls | dev
# Projects live in ~/proj. Templates in ~/nixos/templates win over the-nix-way/dev-templates.
# Inside a git repo the flake files must be git-added, or nix cannot see them.
dev() {
  local repo=github:the-nix-way/dev-templates
  case $1 in
    init)
      [[ -n $2 ]] || { echo "usage: dev init <template>  (dev ls for the list)" >&2; return 1 }
      local src=$repo
      [[ -d /etc/nixos/templates/$2 ]] && src=/etc/nixos
      nix flake init -t "$src#$2" || return
      git rev-parse --git-dir &>/dev/null && git add flake.nix .envrc
      direnv allow
      ;;
    new)
      [[ -n $2 && -n $3 ]] || { echo "usage: dev new <name> <template>" >&2; return 1 }
      mkdir -p ~/proj/$2 && cd ~/proj/$2 || return
      git rev-parse --git-dir &>/dev/null || git init -q
      dev init $3
      ;;
    ls)
      echo "mine:" /etc/nixos/templates/*(/:t)
      nix flake show --json $repo 2>/dev/null | jq -r '.templates | keys[]' | column
      ;;
    "") nix develop ;;
    *) cd ~/proj/$1 ;;
  esac
}
_dev() {
  if (( CURRENT == 2 )); then
    compadd init new ls ~/proj/*(/:t)
  fi
}
compdef _dev dev

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
