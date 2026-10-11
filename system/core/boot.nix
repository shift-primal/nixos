{ pkgs, ... }:

{
    # The bootloader itself is picked per host (hosts/<hostname>/boot.nix).
    boot = {
        loader.efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot";
        };

        kernelPackages = pkgs.linuxPackages_latest;
    };
}
