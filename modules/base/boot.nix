_:

{
    flake.modules.nixos.base =
        { pkgs, ... }:
        {
            # The bootloader itself is picked per host (modules/hosts/<hostname>/boot.nix).
            boot = {
                loader.efi = {
                    canTouchEfiVariables = true;
                    efiSysMountPoint = "/boot";
                };

                # NTFS read/write for the Windows partitions.
                supportedFilesystems = [ "ntfs" ];

                kernelPackages = pkgs.linuxPackages_latest;
            };
        };
}
