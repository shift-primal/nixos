{ pkgs, ... }:

{
    # Secure Boot key tooling; Limine signing is not set up yet.
    environment.systemPackages = [ pkgs.sbctl ];

    boot.loader = {
        systemd-boot.enable = false;

        limine = {
            enable = true;
            # The ESP is 1 GB and is shared with Windows and Arch. Each generation
            # copies a kernel and initrd onto it.
            maxGenerations = 10;
            extraEntries = ''
                /Arch Linux
                  comment: Arch, booted directly from its own ext4 /boot
                  protocol: linux
                  path: guid(6d7539dc-0539-4f0e-adc9-4d70e8e99d65):/boot/vmlinuz-linux
                  cmdline: root=UUID=36ac46bc-091d-486e-a9a1-a6fd7cb1e4ca rw loglevel=3 quiet nvidia_drm.modeset=1 nvidia_drm.fbdev=1
                  module_path: guid(6d7539dc-0539-4f0e-adc9-4d70e8e99d65):/boot/initramfs-linux.img

                /Arch Linux (GRUB)
                  comment: Arch GRUB, fallback until the entry above is tested
                  protocol: efi
                  path: boot():///EFI/GRUB/grubx64.efi

                /Windows
                  comment: Windows Boot Manager
                  protocol: efi
                  path: boot():///EFI/Microsoft/Boot/bootmgfw.efi
            '';
        };
    };
}
