{ pkgs, ... }:

{
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
