# Sourced at the end of the ~/.config/zsh/.zshrc Home Manager generates (modules/shell/zsh.nix),
# after Oh My Zsh, plugins, completion and the prompt are set up. Edits apply on the next shell.

# Vite+ shims on PATH plus the `vp` function `vp env use` needs. Runs after compinit so compdef exists.
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
# Projects live in ~/proj. Templates come from the-nix-way/dev-templates.
# Inside a git repo the flake files must be git-added, or nix cannot see them.
dev() {
  local repo=github:the-nix-way/dev-templates
  case $1 in
    init)
      [[ -n $2 ]] || { echo "usage: dev init <template>  (dev ls for the list)" >&2; return 1 }
      nix flake init -t "$repo#$2" || return
      if [[ $2 == node ]]; then
        for f in oxlintrc oxfmtrc; do cp --update=none /etc/nixos/dotfiles/oxc/$f.json .$f.json; done
      fi
      git rev-parse --git-dir &>/dev/null && git add flake.nix .envrc .ox*rc.json(N)
      direnv allow
      ;;
    new)
      [[ -n $2 && -n $3 ]] || { echo "usage: dev new <name> <template>" >&2; return 1 }
      mkdir -p ~/proj/$2 && cd ~/proj/$2 || return
      git rev-parse --git-dir &>/dev/null || git init -q
      dev init $3
      ;;
    ls)
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

# Pull and switch the homelab from here; modules/system/nix.nix lets sudo run rebuild without a password, so no tty.
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
