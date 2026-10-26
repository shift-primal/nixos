_:

{
    # The hostname is set by each host (modules/hosts/<hostname>/default.nix).
    flake.modules.nixos.base.networking.networkmanager.enable = true;
}
