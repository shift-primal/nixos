_:

{
    # NixOS only on this disk, so the installer's default bootloader is kept.
    flake.modules.nixos.kash-homelab.boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 10;
    };
}
