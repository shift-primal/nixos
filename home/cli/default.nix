{ inputs, pkgs, ... }:

{
  # The terminal, editor, btop and yazi are default apps, see vars.nix.
  home.packages = with pkgs; [
    ripgrep
    fd
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
    gowall
    grok-cli
    inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.stable
  ];
}
