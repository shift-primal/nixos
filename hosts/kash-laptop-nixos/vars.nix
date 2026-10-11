# Per-host values, merged over ../../vars.nix by flake.nix. The hostname comes
# from this folder's name.
{
    # Release this machine was first installed with. Do not bump on upgrades.
    # Must match system.stateVersion in the installer's /etc/nixos/configuration.nix.
    stateVersion = "26.05";
}
