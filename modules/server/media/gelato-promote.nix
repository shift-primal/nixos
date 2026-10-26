_:

{
    # gelato-promote: a Gelato title (gelato.nix) someone plays is requested in Seerr, so Radarr or
    # Sonarr add it through Decypharr and Bazarr gives it synced Norwegian subtitles. Once the real
    # copy is in the library, the Gelato one goes. Streaming from Gelato stays instant; the request
    # only makes the next watch better. _promote.py does the work every two minutes.
    flake.modules.nixos.media =
        { config, pkgs, ... }:
        let
            stateDir = "gelato-promote";
            settings = {
                jellyfin = {
                    url = "http://127.0.0.1:8096";
                    db = "${config.services.jellyfin.dataDir}/data/jellyfin.db";
                };
                seerr = {
                    url = "http://127.0.0.1:${toString config.services.seerr.port}";
                    inherit (config.services.seerr) configDir;
                };
                stateFile = "/var/lib/${stateDir}/state.json";
            };
            promote = pkgs.writers.writePython3 "gelato-promote" {
                flakeIgnore = [ "E501" ];
            } (builtins.readFile ./_promote.py);
        in
        {
            systemd.services.gelato-promote = {
                description = "Request played Gelato titles in Seerr";
                after = [
                    "jellyfin.service"
                    "seerr.service"
                    "media-configure.service"
                ];
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${promote} ${pkgs.writeText "gelato-promote.json" (builtins.toJSON settings)}";
                    StateDirectory = stateDir;
                    StateDirectoryMode = "0700";
                };
            };
            systemd.timers.gelato-promote = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "5min";
                    OnUnitActiveSec = "2min";
                };
            };
        };
}
