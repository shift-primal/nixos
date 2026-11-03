_:

{
    flake.modules.nixos.kash-laptop =
        { lib, ... }:
        {

            boot.loader.systemd-boot = {
                enable = true;
                configurationLimit = 10;
            };

            fileSystems."/boot".options = lib.mkForce [
                "fmask=0077"
                "dmask=0077"
            ];
        };
}
