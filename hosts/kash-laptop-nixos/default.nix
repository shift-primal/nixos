{ vars, ... }:

{
    # hardware-configuration.nix is generated on the laptop itself:
    #   nixos-generate-config --show-hardware-config > hardware-configuration.nix
    imports = [
        ./hardware-configuration.nix
        ./boot.nix
        ./greetd.nix
        ../../system
    ];

    system.stateVersion = vars.stateVersion;
}
