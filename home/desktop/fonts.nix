{ pkgs, ... }:

{
    fonts.fontconfig.enable = true;

    # Monaspace Neon NF is the kitty font (dotfiles/kitty/kitty.conf).
    home.packages = [ pkgs.monaspace ];
}
