_:

let
    mountPoint = "/mnt/data";
in
{
    flake.modules.nixos.kash-homelab = {

        fileSystems.${mountPoint} = {
            device = "/dev/disk/by-label/data";
            fsType = "ext4";

            options = [
                "nofail"
                "x-systemd.device-timeout=10s"
            ];
        };

        homelab.media.root = mountPoint;

        services.immich.mediaLocation = "${mountPoint}/immich";

        services.opencloud.stateDir = "${mountPoint}/opencloud";

        services.beszel.agent.environment.EXTRA_FILESYSTEMS = mountPoint;
    };
}
