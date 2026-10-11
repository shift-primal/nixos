{ lib, ... }:

{
    # NixOS only on this disk, so the installer's default bootloader is kept.
    boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 10;
    };

    # The installer generated 0022 masks, which leave /boot/loader/random-seed world-readable
    # (bootctl logs it as a security hole). Overrides hardware-configuration.nix, which gets regenerated.
    fileSystems."/boot".options = lib.mkForce [
        "fmask=0077"
        "dmask=0077"
    ];
}
