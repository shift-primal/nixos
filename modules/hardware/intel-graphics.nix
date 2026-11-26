{
    flake.modules.nixos.intel-graphics =
        { pkgs, ... }:
        {
            boot.initrd.kernelModules = [ "i915" ];

            hardware.graphics = {
                enable = true;
                extraPackages = [ pkgs.intel-media-driver ];
            };
            environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
        };
}
