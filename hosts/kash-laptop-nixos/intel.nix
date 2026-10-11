{ pkgs, ... }:

{
    # VA-API for Alder Lake (iHD), so Firefox and mpv decode video on the GPU.
    hardware.graphics = {
        enable = true;
        extraPackages = [ pkgs.intel-media-driver ];
    };

    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
