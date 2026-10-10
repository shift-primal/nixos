{ pkgs, ... }:
{
  # Login shell is zsh, so the system module must be on. It adds the Nix
  # profile directories to zsh's PATH. Without that, login can fail.
  #
  # Home Manager owns compinit and the prompt. The system compinit runs
  # from /etc/zshrc, before ~/.zshrc, so it would miss later fpath entries
  # and run a second time. The default "suse" prompt fights Starship.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    promptInit = "";
    histSize = 10000;
    histFile = "/home/kasper/.config/zsh/.zsh_history";
  };

  users.users.kasper = {
    isNormalUser = true;
    description = "Kasper Haugestøl";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "render"
      "input"
      "docker"
    ];
  };
}
