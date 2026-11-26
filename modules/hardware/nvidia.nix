{
    flake.modules.nixos.nvidia =
        { config, ... }:
        {
            services.xserver.videoDrivers = [ "nvidia" ];
            hardware = {
                graphics.enable = true;
                nvidia = {
                    modesetting.enable = true;
                    powerManagement.enable = false;
                    powerManagement.finegrained = false;
                    open = true;
                    nvidiaSettings = true;
                    package = config.boot.kernelPackages.nvidiaPackages.latest;
                };
            };

            environment.sessionVariables = {
                LIBVA_DRIVER_NAME = "nvidia";
                GBM_BACKEND = "nvidia-drm";
                __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            };

            hm.xdg.desktopEntries.nvidia-settings = {
                name = "nvidia-settings";
                exec = "nvidia-settings";
                noDisplay = true;
            };
        };
}
