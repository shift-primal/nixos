{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/system
  ];

  system.stateVersion = "26.05";
}
