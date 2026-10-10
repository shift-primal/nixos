{ config, lib, ... }:
{

  home.file.".config/zsh/.zshrc".enable = lib.mkForce false;
  home.file.".config/zsh/hm-init.zsh".text = config.programs.zsh.initContent;

  programs = {
    zsh = {
      enable = true;

      dotDir = "${config.home.homeDirectory}/.config/zsh";

      defaultKeymap = "emacs";
      enableCompletion = true;

      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        size = 10000;
        extended = true;
        path = "${config.home.homeDirectory}/.config/zsh/.zsh_history";
      };

      localVariables = {
        DISABLE_AUTO_TITLE = "true";
        COMPLETION_WAITING_DOTS = "true";
      };

      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
        PNPM_HOME = "$HOME/.local/share/pnpm";
        _ZO_DOCTOR = "0";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "aliases"
          "archlinux"
          "chezmoi"
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

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
    };

    starship = {
      enable = true;
    };

    fzf = {
      enable = true;
    };
  };

}
