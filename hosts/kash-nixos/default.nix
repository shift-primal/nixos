{ vars, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../system
  ];

  system.stateVersion = vars.stateVersion;
}
