{ config, lib, ... }:

let
  dotDir = "${config.xdg.configHome}/zsh";
  dotDirRel = lib.removePrefix "${config.home.homeDirectory}/" dotDir;
in
{
  # .zshrc is the live-edited dotfiles/zsh/.zshrc (see home/dotfiles.nix).
  # Everything Home Manager generates goes to hm-init.zsh, which that file sources.
  home.file."${dotDirRel}/.zshrc".enable = lib.mkForce false;
  home.file."${dotDirRel}/hm-init.zsh".text = config.programs.zsh.initContent;

  programs.zsh = {
    enable = true;
    inherit dotDir;

    defaultKeymap = "emacs";
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      extended = true;
      path = "${dotDir}/.zsh_history";
    };

    localVariables = {
      DISABLE_AUTO_TITLE = "true";
      COMPLETION_WAITING_DOTS = "true";
    };

    # EDITOR and VISUAL are set system-wide from vars.nix (system/core/packages.nix).
    sessionVariables = {
      SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
      PNPM_HOME = "$HOME/.local/share/pnpm";
      _ZO_DOCTOR = "0";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "aliases"
        "colorize"
        "eza"
      ];
      extraConfig = ''
        # Nix profile completion dirs fail compaudit and stall the first prompt.
        ZSH_DISABLE_COMPFIX=true
        zstyle ':omz:update' mode reminder
      '';
    };

    initContent = lib.mkOrder 560 ''
      path=(
        "$HOME/.local/bin"
        "$PNPM_HOME/bin"
        "$HOME/.cargo/bin"
        $path
      )
    '';
  };
}
