# Host entry. Hardware stays here because nixos-generate-config writes
# /etc/nixos/hardware-configuration.nix, and /etc/nixos points at this repo.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/system
  ];

  # First NixOS version installed on this machine. Do not change.
  system.stateVersion = "26.05";
}
