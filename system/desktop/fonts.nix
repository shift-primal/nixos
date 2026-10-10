{ pkgs, ... }:

{
    # System-wide fallback fonts. The user's own fonts are in home/desktop/fonts.nix.
    fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
    ];
}
