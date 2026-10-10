{
  imports = [
  ./desktop.nix
  ./dotfiles.nix
  ./noctalia.nix
  ./packages
  ./shell.nix
];

  home.username = "kasper";
  home.homeDirectory = "/home/kasper";

  # First Home Manager version for this user. Do not change.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
