# PLACEHOLDER so the host evaluates before the machine exists. Do not install with it:
# overwrite it on the ProDesk with
#   nixos-generate-config --show-hardware-config > _hardware-configuration.nix
{ config, lib, ... }:

{
    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
    };

    fileSystems."/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
