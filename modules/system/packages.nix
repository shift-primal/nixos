{ pkgs, ... }:
{
  # Still on PATH from a TTY if Home Manager fails to activate.
  environment.systemPackages = with pkgs; [
    git
    neovim
    wget
  ];
}
