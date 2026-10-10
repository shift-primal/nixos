{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty
    neovim
    ripgrep
    fd
    btop
    yazi
    eza
    fastfetch
    lazygit
    trash-cli
    sqlite
    unzip
  ];
}
