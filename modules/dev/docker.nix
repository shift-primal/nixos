{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.dev = {
        virtualisation.docker.enable = true;
        users.users.${vars.user.name}.extraGroups = [ "docker" ];
    };

    flake.modules.homeManager.dev =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                dockerfile-language-server
                docker-compose-language-service
                hadolint
            ];
        };
}
