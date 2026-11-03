{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.desktop = {
        virtualisation.docker.enable = true;
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
