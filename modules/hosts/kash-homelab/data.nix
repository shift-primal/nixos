_:

{
    # The 4 TB HDD. Kept out of _hardware-configuration.nix so regenerating that file can't drop it.
    # Mounted by label, so the disk needs one: `sudo e2label /dev/sdX1 data` on an existing ext4
    # partition, or `mkfs.ext4 -L data` on a new one (wipes it).
    flake.modules.nixos.kash-homelab.fileSystems."/mnt/data" = {
        device = "/dev/disk/by-label/data";
        fsType = "ext4";
        # Boot carries on without it, so a dead or unplugged disk doesn't lock out SSH.
        options = [
            "nofail"
            "x-systemd.device-timeout=10s"
        ];
    };
}
