{ pkgs, ... }:

{
  # Docker itself is in system/services/docker.nix.
  home.packages = with pkgs; [
    dockerfile-language-server
    docker-compose-language-service
    hadolint
  ];
}
