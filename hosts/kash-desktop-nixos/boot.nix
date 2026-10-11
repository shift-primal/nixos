{ pkgs, ... }:

{
    # sbctl: Secure Boot key tooling; Limine signing is not set up yet.
    # efibootmgr: list and remove stale UEFI boot entries.
    environment.systemPackages = with pkgs; [
        sbctl
        efibootmgr
    ];

    boot.loader = {
        systemd-boot.enable = false;

        limine = {
            enable = true;
            # The ESP is 1 GB and is shared with Windows and Arch. Each generation
            # copies a kernel and initrd onto it.
            maxGenerations = 10;
            extraEntries = ''
                /Arch Linux
                  comment: Arch kernel and initramfs copied to /boot/arch on the ESP
                  protocol: linux
                  # Limine could not open the kernel on Arch's own ext4 /boot (guid() and uuid() both
                  # failed), so Arch's files are copied here. Keep them in sync after Arch kernel updates.
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
}
