{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        wl-clipboard
        cliphist
        wl-clip-persist
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
        libnotify
        gowall
    ];
}
