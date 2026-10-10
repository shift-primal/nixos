{
  imports = [
    ./desktop.nix
    ./dotfiles.nix
    ./noctalia.nix
    ./packages
    ./shell.nix
  ];

  home = {
    username = "kasper";
    homeDirectory = "/home/kasper";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
