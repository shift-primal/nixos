{ lib, ... }:

{
    networking.hostName = "kash-laptop";
    system.stateVersion = "26.05";

    boot.loader = {
        systemd-boot = {
            enable = true;
            configurationLimit = 10;
        };
        timeout = 0;
    };

    fileSystems."/boot".options = lib.mkForce [
        "fmask=0077"
        "dmask=0077"
    ];

    services.xserver.xkb.options = "caps:swapescape";
}
