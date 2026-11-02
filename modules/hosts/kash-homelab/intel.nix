_:

{
    # HD 530 (Skylake, Gen9) for Jellyfin and Immich transcoding (modules/homelab/media/jellyfin.nix,
    # modules/homelab/apps/immich.nix). VA-API rather
    # than QSV: QSV on Gen9 needs intel-media-sdk, which is end of life and marked insecure in nixpkgs.
    flake.modules.nixos.kash-homelab =
        { pkgs, ... }:
        {
            hardware.graphics = {
                enable = true;
                extraPackages = with pkgs; [
                    intel-media-driver
                    # OpenCL for HDR tone mapping; the current compute-runtime dropped Gen9.
                    intel-compute-runtime-legacy1
                ];
            };

            systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";

            # Video engine load in Beszel (modules/homelab/ops/monitoring/beszel.nix), to see transcodes.
            services.beszel.agent.environment.GPU_COLLECTOR = [ "intel_gpu_top" ];

            services.jellyfin = {
                hardwareAcceleration = {
                    enable = true;
                    type = "vaapi";
                    device = "/dev/dri/renderD128";
                };
                # Nix owns the transcoding settings: changes made in the dashboard are reset on restart.
                forceEncodingConfig = true;
                transcoding = {
                    enableHardwareEncoding = true;
                    # What Gen9 decodes in hardware. 10-bit HEVC and VP9 fall back to the CPU.
                    hardwareDecodingCodecs = {
                        h264 = true;
                        hevc = true;
                        mpeg2 = true;
                        vc1 = true;
                        vp8 = true;
                    };
                    # H.264 is always on; Gen9 also encodes 8-bit HEVC.
                    hardwareEncodingCodecs.hevc = true;
                };
            };

            # Immich transcodes phone videos (HEVC, often 10-bit) to H.264 for playback in the browser.
            # The module hides /dev from Immich unless a device is listed here.
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
