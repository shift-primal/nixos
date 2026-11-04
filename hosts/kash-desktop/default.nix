{ config, pkgs, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ../../system.nix
        ../../packages.nix
        ../../desktop.nix
        ../../hardware.nix
        ../../dev.nix
        ../../home.nix
    ];

    networking.hostName = "kash-desktop";
    system.stateVersion = "26.05";
    environment = {

        systemPackages = with pkgs; [
            sbctl
            efibootmgr
        ];

        sessionVariables = {
            LIBVA_DRIVER_NAME = "nvidia";
            GBM_BACKEND = "nvidia-drm";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            WLR_NO_HARDWARE_CURSORS = "1";
        };
    };

    boot.loader = {
        systemd-boot.enable = false;
        limine = {
            enable = true;
            maxGenerations = 10;
            extraEntries = ''
                /Arch Linux
                  comment: Arch kernel and initramfs copied to /boot/arch on the ESP
                  protocol: linux
                  path: boot():/arch/vmlinuz-linux
                  cmdline: root=UUID=36ac46bc-091d-486e-a9a1-a6fd7cb1e4ca rw loglevel=3 quiet nvidia_drm.modeset=1 nvidia_drm.fbdev=1
                  module_path: boot():/arch/initramfs-linux.img
                /Windows
                  comment: Windows Boot Manager
                  protocol: efi
                  path: boot():///EFI/Microsoft/Boot/bootmgfw.efi
            '';
        };
    };
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
}
