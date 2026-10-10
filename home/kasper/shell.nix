{ config, lib, ... }:
{
  programs.zsh = {
    enable = true;
    # xdg.enable is off, so the module default would be ~/.zshrc. Keep the
    # shell config next to the history file set in the system zsh module.
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    # Same emacs bindings the new-user .zshrc set with `bindkey -e`.
    defaultKeymap = "emacs";
    enableCompletion = true;

    # Fish-style grey suggestions as you type. Right arrow accepts one.
    # The old dot_zshrc listed these as Oh My Zsh plugins, but they are not
    # shipped inside the Nix Oh My Zsh package. These options load them.
    autosuggestion.enable = true;
    # Color commands as they are typed. Loaded after Oh My Zsh on purpose.
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      extended = true;
      path = "${config.home.homeDirectory}/.config/zsh/.zsh_history";
    };

    # Brought over from ~/dotfiles/dot_zshrc. Oh My Zsh reads these before
    # it is sourced, which is when localVariables are written.
    localVariables = {
      DISABLE_AUTO_TITLE = "true";
      COMPLETION_WAITING_DOTS = "true";
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      # Bitwarden SSH agent. The socket is created by the desktop app.
      SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
      PNPM_HOME = "$HOME/.local/share/pnpm";
      # zoxide nags when its data dir is missing. The old config silenced it.
      _ZO_DOCTOR = "0";
    };

    # Aliases live in ~/nixos/dotfiles/zsh/.zshrc, which is the linked rc.

    oh-my-zsh = {
      enable = true;
      # Starship draws the prompt later in .zshrc. A theme here would be replaced.
      # zoxide, zsh-autosuggestions, and zsh-syntax-highlighting were in the
      # old plugins list. zoxide is programs.zoxide below. The other two are
      # the options above. Listing them here would look for missing plugins.
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

    # Oh My Zsh runs compinit while it is sourced. Grok has to be on fpath
    # before that, and the installer only patched bash. The path entries are
    # the ones the old dot_zshrc prepended, in the same order.
    initContent = lib.mkOrder 560 ''
      path=(
        "$HOME/.grok/bin"
        "$HOME/.local/bin"
        "$PNPM_HOME/bin"
        "$HOME/.cargo/bin"
        $path
      )
      fpath=("$HOME/.grok/completions/zsh" $fpath)
    '';
  };

  # programs.zsh would install its own .zshrc. dotfiles.nix links that path
  # to ~/nixos/dotfiles/zsh/.zshrc, which sources the file below.
  home.file.".config/zsh/.zshrc".enable = lib.mkForce false;
  home.file.".config/zsh/hm-init.zsh".text = config.programs.zsh.initContent;

  # `eval "$(direnv hook zsh)"` from the old dot_zshrc.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide.enable = true;

  programs.starship = {
    enable = true;
    # Config is ~/nixos/dotfiles/starship.toml, linked to
    # ~/.config/starship.toml. Leaving presets empty keeps Home Manager
    # from writing a second file over that link. The toml already includes
    # the nerd-font symbols preset plus the Noctalia palette.
  };

  # Ctrl-R history, Ctrl-T files, Alt-C directories. fzf is already installed.
  programs.fzf.enable = true;
}
