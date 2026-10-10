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
}
