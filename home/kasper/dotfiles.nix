{ config, ... }:
let
  root = "/home/kasper/nixos/dotfiles";
  link = name: config.lib.file.mkOutOfStoreSymlink "${root}/${name}";
in
{
  xdg.configFile."hypr".source = link "hypr";
  xdg.configFile."nvim".source = link "nvim";
  xdg.configFile."kitty".source = link "kitty";
  xdg.configFile."starship.toml".source = link "starship.toml";
  xdg.configFile."zsh/.zshrc".source = link "zsh/.zshrc";
}
