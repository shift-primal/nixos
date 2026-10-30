_:

{
    # Immich: photo and video backup from the phones, with face and object search. Open on the home
    # LAN and the tailnet at http://<hostname>:2283, and on the internet at homelab.immich.domain
    # through the Cloudflare tunnel, so shared links work for anyone. The tunnel caps uploads at
    # 100 MB, so the app should back up over the LAN or Tailscale address (Settings → Networking).
    # The first visit creates the admin account.
    # Where the photos live is per machine (modules/hosts/kash-homelab/data.nix), and so is the GPU
    # side (intel.nix).
    flake.modules.nixos.homelab =
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
            options.homelab.immich.domain = lib.mkOption {
                type = lib.types.str;
                description = "Public domain Caddy serves Immich on, through the tunnel (cloudflared.nix).";
                example = "photos.example.com";
            };

            config.services.immich = {
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
                    # Base of shared-album links.
                    server.externalDomain = "https://${config.homelab.immich.domain}";
                };
            };

            # No Cloudflare Access in front: the phone app can't pass it. Immich's own login guards it.
            config.services.caddy.virtualHosts."http://${config.homelab.immich.domain}".extraConfig = ''
                reverse_proxy 127.0.0.1:${toString cfg.port}
            '';

            # The media disk is mounted nofail. Without it Immich would start on an empty folder, so
            # it waits for the mount instead. The module only fixes permissions on an existing folder
            # (an `e` line); `d` also creates it, and two lines for one path would clash.
            config.systemd.tmpfiles.settings.immich.${cfg.mediaLocation} = lib.mkForce {
                d = {
                    inherit (cfg) user group;
                    mode = "0700";
                };
            };
            config.systemd.services.immich-server.unitConfig.RequiresMountsFor = [ cfg.mediaLocation ];

            # The module puts machine learning on 3003, which homelab.apps already gives to spot
            # (modules/hosts/kash-homelab/apps.nix); whichever starts second crash-loops. 2284 sits
            # next to Immich and outside the apps' 300x range.
            config.services.immich.machine-learning.environment.IMMICH_PORT = lib.mkForce "2284";
            config.services.immich.environment.IMMICH_MACHINE_LEARNING_URL =
                lib.mkForce "http://localhost:2284";

            # 12 GB shared with Jellyfin and the rest. The face and search models take 1-2 GB while a
            # job runs and unload after 5 minutes idle; the cap keeps a big first import from
            # starving the box. Background work also yields the CPU to Jellyfin's transcodes.
            config.systemd.services.immich-machine-learning.serviceConfig = {
                MemoryHigh = "3G";
                MemoryMax = "4G";
            };
            config.systemd.slices.system-immich.sliceConfig.CPUWeight = 50;

            # Originals (upload/, library/) and profile pictures. Thumbnails and transcoded videos are
            # rebuilt from the originals (Administration → Jobs), so they stay out of R2.
            config.homelab.backup = {
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
