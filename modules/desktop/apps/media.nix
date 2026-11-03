_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                v4l-utils
                slurp
                grim
                satty
                hyprpicker
                imagemagick
                wev
                (tesseract.override {
                    enableLanguages = [
                        "eng"
                        "nor"
                    ];
                })
                zbar
                gifski
            ];
        };
}
