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
    gh
    trash-cli
    sqlite
    lazysql
    rbw
    tree
    unzip
    zip
    _7zz
  ];
}
