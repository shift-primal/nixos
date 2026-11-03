_:

{

    flake.modules.nixos.kash-homelab.boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 10;
    };
}
