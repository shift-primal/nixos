{ pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = false;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
      };

      grub2-theme = {

        enable = true;
        theme = "stylish";
        footer = true;
        screen = "2k";
      };

    };

    kernelPackages = pkgs.linuxPackages_latest;
  };

  # All three monitors are 2560x1440, which this theme calls 2k.

}
