{ config, ... }:
let
  # Strings, not Nix paths. A Nix path would be copied into the store and
  # would stop tracking edits under dotfiles/.
  root = "/home/kasper/nixos/dotfiles";
  link = name: config.lib.file.mkOutOfStoreSymlink "${root}/${name}";
in
{
  xdg.configFile."hypr".source = link "hypr";
  xdg.configFile."nvim".source = link "nvim";
  xdg.configFile."kitty".source = link "kitty";
  # Starship reads this path (or $STARSHIP_CONFIG). Noctalia writes its
  # palette through the symlink into this file.
  xdg.configFile."starship.toml".source = link "starship.toml";
  # programs.zsh still generates hm-init.zsh. This file sources that, then
  # holds aliases. shell.nix clears the generated .zshrc text so this link wins.
  xdg.configFile."zsh/.zshrc".source = link "zsh/.zshrc";
}
