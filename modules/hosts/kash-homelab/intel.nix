_:

{

    flake.modules.nixos.kash-homelab =
        { pkgs, ... }:
        {
            hardware.graphics = {
                enable = true;
                extraPackages = with pkgs; [
                    intel-media-driver

                    intel-compute-runtime-legacy1
                ];
            };

            systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";

            services.beszel.agent.environment.GPU_COLLECTOR = [ "intel_gpu_top" ];

            services.jellyfin = {
                hardwareAcceleration = {
                    enable = true;
                    type = "vaapi";
                    device = "/dev/dri/renderD128";
                };

                forceEncodingConfig = true;
                transcoding = {
                    enableHardwareEncoding = true;

                    hardwareDecodingCodecs = {
                        h264 = true;
                        hevc = true;
                        mpeg2 = true;
                        vc1 = true;
                        vp8 = true;
                    };

                    hardwareEncodingCodecs.hevc = true;
                };
            };

            services.immich = {
                accelerationDevices = [ "/dev/dri/renderD128" ];
                environment.LIBVA_DRIVER_NAME = "iHD";
                settings.ffmpeg = {
                    accel = "vaapi";
                    accelDecode = true;
                };
            };
            users.users.immich.extraGroups = [
                "video"
                "render"
            ];
        };
}
