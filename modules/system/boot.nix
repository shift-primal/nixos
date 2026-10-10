{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
  };

  # All three monitors are 2560x1440, which this theme calls 2k.
  boot.loader.grub2-theme = {
    enable = true;
    theme = "stylish";
    footer = true;
    screen = "2k";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
