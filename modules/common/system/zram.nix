_:

{
    flake.modules.nixos.common = {
        # Neither host has a swap partition; compressed swap in RAM instead.
        zramSwap.enable = true;
    };
}
