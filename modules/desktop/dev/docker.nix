{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop = {
        virtualisation.docker.enable = true;
        # Containers keep running while dockerd restarts. Without it a switch that changes Docker
        # stops every container, and the oci-containers units (aiostreams.nix) see a clean exit and
        # stay down, since they only restart on failure.
        virtualisation.docker.daemon.settings.live-restore = true;
        users.users.${vars.user.name}.extraGroups = [ "docker" ];
    };

    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                dockerfile-language-server
                docker-compose-language-service
                hadolint
            ];
        };
}
