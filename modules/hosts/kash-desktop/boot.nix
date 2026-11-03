_:

{
    flake.modules.nixos.kash-desktop =
        { pkgs, ... }:
        {

            environment.systemPackages = with pkgs; [
                sbctl
                efibootmgr
            ];

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
        };
}
