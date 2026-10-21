{ pkgs, ... }:

{
    home.packages = with pkgs; [
        easyeffects # audio effects, runs as a service from autostart.lua
        v4l-utils # webcam controls, autostart.lua turns off autofocus
        slurp # region picker for the screen recording keybind
        grim # screenshots, used by satty and the screen toolkit
        satty # screenshot annotation
        hyprpicker # color picker
        imagemagick # screen toolkit's color-picker.sh and palette/lens scripts call magick
        wev # key event viewer
        (tesseract.override {
            enableLanguages = [
                "eng"
                "nor"
            ];
        }) # OCR in the screen toolkit
        zbar # QR codes
        gifski # convert videos to gif
    ];
}
