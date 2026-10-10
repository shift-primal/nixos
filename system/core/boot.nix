{ pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot.enable = false;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      limine = {
        enable = true;
        # The ESP is 1 GB and is shared with Windows and Arch. Each generation
        # copies a kernel and initrd onto it.
        maxGenerations = 10;
        extraEntries = ''
          /Arch Linux
            comment: Arch GRUB
            protocol: efi
            path: boot():///EFI/GRUB/grubx64.efi

          /Windows
            comment: Windows Boot Manager
            protocol: efi
            path: boot():///EFI/Microsoft/Boot/bootmgfw.efi
        '';
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };
}
