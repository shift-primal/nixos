{ vars, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ./boot.nix
        ./nvidia.nix
        ../../system
    ];

    system.stateVersion = vars.stateVersion;
}
