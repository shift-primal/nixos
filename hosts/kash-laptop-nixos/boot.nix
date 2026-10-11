_:

{
    # NixOS only on this disk, so the installer's default bootloader is kept.
    boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 10;
    };
}
