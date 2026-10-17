{ pkgs, ... }:

{
    fonts.fontconfig.enable = true;

    # Monaspace Neon NF is the kitty font (dotfiles/kitty/kitty.conf).
    home.packages = with pkgs; [
        monaspace
        bagnard
        circular-std
        (google-fonts.override {
            fonts = [
                "DMSerifDisplay"
                "JosefinSans"
            ];
        })
    ];
}
