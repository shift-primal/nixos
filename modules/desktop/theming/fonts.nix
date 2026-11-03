_:

{

    flake.modules.nixos.desktop =
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

    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            fonts.fontconfig.enable = true;

            home.packages = with pkgs; [
                monaspace
            ];
        };
}
