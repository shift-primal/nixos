_:

{
    flake.modules.nixos.common =
        { pkgs, ... }:
        {

            boot = {
                loader.efi = {
                    canTouchEfiVariables = true;
                    efiSysMountPoint = "/boot";
                };

                supportedFilesystems = [ "ntfs" ];

                kernelPackages = pkgs.linuxPackages_latest;
            };
        };
}
