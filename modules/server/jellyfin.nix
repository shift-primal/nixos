{ config, ... }:

let
    inherit (config) vars;
in
{
    # Jellyfin, reachable over Tailscale only: streaming video through the Cloudflare tunnel breaks
    # Cloudflare's terms, so it gets no Caddy vhost. Open http://<hostname>:8096 from the tailnet.
    # The GPU side (VA-API, codecs) is per machine: modules/hosts/kash-homelab/intel.nix.
    flake.modules.nixos.jellyfin =
        { config, lib, ... }:
        let
            cfg = config.homelab.jellyfin;
        in
        {
            options.homelab.jellyfin.mediaDir = lib.mkOption {
                type = lib.types.str;
                description = "Folder holding the libraries, one subfolder each.";
                example = "/mnt/data/media";
            };

            config = {
                services.jellyfin.enable = true;

                # Jellyfin listens on every interface; the firewall lets only the tailnet in.
                networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8096 ];

                # Shared by Jellyfin (reads) and the user (copies media in over SSH/scp). setgid keeps
                # new files in the group.
                users.groups.media.members = [
                    "jellyfin"
                    vars.user.name
                ];
                systemd.tmpfiles.settings.jellyfin-media =
                    lib.genAttrs
                        (
                            [ cfg.mediaDir ]
                            ++ map (dir: "${cfg.mediaDir}/${dir}") [
                                "movies"
                                "shows"
                                "music"
                            ]
                        )
                        (_: {
                            d = {
                                user = vars.user.name;
                                group = "media";
                                mode = "2775";
                            };
                        });

                # The media disk is mounted nofail. Without it a library scan would find empty folders
                # and drop every item, so Jellyfin waits for the mount instead.
                systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ cfg.mediaDir ];

                # Config, users, watch history and fetched metadata. The media itself is not copied
                # off-site (backup.nix); the cache dir is outside this path.
                homelab.backup.paths = [ config.services.jellyfin.dataDir ];
            };
        };
}
