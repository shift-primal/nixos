_:

{
    # Immich: photo and video backup from the phones, with face and object search. Reachable from the
    # home LAN and the tailnet but not the internet: the Cloudflare tunnel caps uploads at 100 MB, so
    # longer videos from the app would fail through it. Open http://<hostname>:2283; the first visit
    # creates the admin account.
    # Where the photos live is per machine (modules/hosts/kash-homelab/data.nix), and so is the GPU
    # side (intel.nix).
    flake.modules.nixos.immich =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            cfg = config.services.immich;
            postgres = config.services.postgresql.package;
        in
        {
            services.immich = {
                enable = true;
                # Every interface, like Jellyfin: phones at home need no Tailscale.
                host = "";
                openFirewall = true;
                # Postgres and Redis come with the module, over Unix sockets, so there is no password
                # to keep in sops.

                # Nix owns the server settings: the admin page shows them read-only. Anything not set
                # here (or in intel.nix) keeps Immich's default.
                settings = {
                    # Files sorted into year/date folders rather than by upload id, so the library is
                    # still browsable on the disk (or in a restore) without Immich.
                    storageTemplate = {
                        enabled = true;
                        template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
                    };
                    # The nightly backup dumps the database itself (below); Immich's own dumps would
                    # only be a second copy of it.
                    backup.database.enabled = false;
                };
            };

            # The media disk is mounted nofail. Without it Immich would start on an empty folder, so
            # it waits for the mount instead. The module only fixes permissions on an existing folder
            # (an `e` line); `d` also creates it, and two lines for one path would clash.
            systemd.tmpfiles.settings.immich.${cfg.mediaLocation} = lib.mkForce {
                d = {
                    inherit (cfg) user group;
                    mode = "0700";
                };
            };
            systemd.services.immich-server.unitConfig.RequiresMountsFor = [ cfg.mediaLocation ];

            # 12 GB shared with Jellyfin and the rest. The face and search models take 1-2 GB while a
            # job runs and unload after 5 minutes idle; the cap keeps a big first import from
            # starving the box. Background work also yields the CPU to Jellyfin's transcodes.
            systemd.services.immich-machine-learning.serviceConfig = {
                MemoryHigh = "3G";
                MemoryMax = "4G";
            };
            systemd.slices.system-immich.sliceConfig.CPUWeight = 50;

            # Originals (upload/, library/) and profile pictures. Thumbnails and transcoded videos are
            # rebuilt from the originals (Administration → Jobs), so they stay out of R2.
            homelab.backup = {
                paths = [ cfg.mediaLocation ];
                exclude = map (dir: "${cfg.mediaLocation}/${dir}") [
                    "thumbs"
                    "encoded-video"
                    "backups"
                ];
                # Albums, faces, people and metadata. Restore into an empty database before Immich
                # first starts: gunzip -c immich.sql.gz | sudo -u postgres psql immich
                dumps."immich.sql.gz" = ''
                    ${pkgs.util-linux}/bin/runuser -u postgres -- ${postgres}/bin/pg_dump --clean --if-exists ${cfg.database.name} |
                        ${lib.getExe pkgs.gzip}
                '';
            };
        };
}
