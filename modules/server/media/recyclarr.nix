_:

let
    # TRaSH Guides profiles (https://trash-guides.info): what Sonarr and Radarr grab, ranked by
    # release group and source. The ids are from the guide's JSON (docs/json/<app>/).
    profiles = {
        sonarr = {
            name = "WEB-1080p";
            trashId = "72dae194fc92bf828f32cde7744e51a1";
            notOriginal = "ae575f95ab639ba5d15f663bf019e3e8";
        };
        radarr = {
            name = "HD Bluray + WEB";
            trashId = "d1d67249d3890e49bc12e275d989a7e9";
            notOriginal = "d6e9318c875905d6cfb5bee961afcea9";
        };
    };
in
{
    # Recyclarr syncs those profiles and their custom formats into Sonarr and Radarr, and again daily
    # as the guide changes. media-configure (configure.nix) runs it once the apps are up, then moves
    # every show and movie onto the profile.
    flake.modules.nixos.media =
        { config, lib, ... }:
        let
            keysDir = config.homelab.media.keysDir;
            instance = app: type: {
                base_url = "http://127.0.0.1:${toString config.services.${app}.settings.server.port}";
                api_key._secret = "${keysDir}/${app}";
                # Only removes formats Recyclarr made itself, never NORDiC.
                delete_old_custom_formats = true;
                quality_definition = { inherit type; };
                quality_profiles = [
                    {
                        trash_id = profiles.${app}.trashId;
                        reset_unmatched_scores = {
                            enabled = true;
                            # Scored by media-configure.
                            except = [ "NORDiC" ];
                        };
                    }
                ];
                # Original audio only: everything else scores -10000, below the minimum of 0.
                custom_formats = [
                    {
                        trash_ids = [ profiles.${app}.notOriginal ];
                        assign_scores_to = [ { trash_id = profiles.${app}.trashId; } ];
                    }
                ];
            };
        in
        {
            options.homelab.media.profiles = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = lib.mapAttrs (_: p: p.name) profiles;
                readOnly = true;
                description = "Name of the quality profile Recyclarr makes, per app.";
            };

            config.services.recyclarr = {
                enable = true;
                configuration = {
                    sonarr.shows = instance "sonarr" "series";
                    radarr.movies = instance "radarr" "movie";
                };
            };
        };
}
