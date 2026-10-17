{ vars, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ./boot.nix
        ./nvidia.nix
        ./tinyproxy.nix
        ../../system
    ];

    system.stateVersion = vars.stateVersion;
}
