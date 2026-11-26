{
    flake.modules.nixos.boot =
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

            zramSwap.enable = true;
        };
}
