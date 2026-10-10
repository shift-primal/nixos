{ pkgs, ... }:

{
  home.packages = with pkgs; [
    python3
    gcc
    tree-sitter
    cargo
    nodejs
    pnpm
    dotnet
  ];
}
