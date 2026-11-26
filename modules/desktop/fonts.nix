{
    flake.modules.nixos.fonts =
        { pkgs, ... }:
        {
            fonts.packages = with pkgs; [
                (google-fonts.override { fonts = [ "Figtree" ]; })
                noto-fonts
                noto-fonts-cjk-sans
                noto-fonts-cjk-serif
                noto-fonts-color-emoji
                corefonts
                monaspace
            ];

            hm.fonts.fontconfig.enable = true;
        };
}
