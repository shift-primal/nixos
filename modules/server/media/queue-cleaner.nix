_:

{
    # Every 15 minutes, fails Sonarr/Radarr downloads that rdt-client is stuck on (Real-Debrid
    # refused the torrent, or it has no seeders) so they blocklist it and grab another release.
    # The apps only warn about these and never give up on their own. See _queue_cleaner.py.
    flake.modules.nixos.media =
        { config, pkgs, ... }:
        let
            app = name: {
                url = "http://127.0.0.1:${toString config.services.${name}.settings.server.port}";
                configFile = "${config.services.${name}.dataDir}/config.xml";
            };
            settings = {
                # Since the grab; Real-Debrid usually has a cached torrent ready within minutes.
                minutes = 30;
                apps = {
                    sonarr = app "sonarr";
                    radarr = app "radarr";
                };
            };
            cleaner = pkgs.writers.writePython3 "media-queue-cleaner" {
                flakeIgnore = [ "E501" ];
            } (builtins.readFile ./_queue_cleaner.py);
        in
        {
            systemd.services.media-queue-cleaner = {
                description = "Fail stuck rdt-client downloads in Sonarr and Radarr";
                after = [
                    "sonarr.service"
                    "radarr.service"
                ];
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${cleaner} ${pkgs.writeText "media-queue-cleaner.json" (builtins.toJSON settings)}";
                };
            };
            systemd.timers.media-queue-cleaner = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "15min";
                    OnUnitActiveSec = "15min";
                };
            };
        };
}
