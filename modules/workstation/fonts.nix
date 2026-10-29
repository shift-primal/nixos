_:

{
    # System-wide fallback fonts.
    flake.modules.nixos.workstation =
        { pkgs, ... }:
        {
            fonts.packages = with pkgs; [
                noto-fonts
                noto-fonts-cjk-sans
                noto-fonts-cjk-serif
                noto-fonts-color-emoji
                corefonts
            ];
        };

    # The user's own fonts. Monaspace Neon NF is the kitty font (dotfiles/kitty/kitty.conf).
    flake.modules.homeManager.workstation =
        { pkgs, ... }:
        {
            fonts.fontconfig.enable = true;

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
        };
}
