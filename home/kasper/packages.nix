{ pkgs, ... }:
let
  # Hyprland binds Super+Shift+E to `betterbird`. That package is not in nixpkgs.
  betterbird = pkgs.writeShellScriptBin "betterbird" ''
    exec ${pkgs.thunderbird}/bin/thunderbird "$@"
  '';
in
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
    direnv
	lazygit
	python3
	gcc
	tree-sitter
	trash-cli
	sqlite
	unzip
	cargo

    firefox
    vesktop
    spotify-player
    bitwarden-desktop
    thunderbird
    betterbird

    wl-clipboard
    cliphist
    wl-clip-persist
    slurp
    easyeffects
    v4l-utils

    bun
    nodejs
  ];
}
