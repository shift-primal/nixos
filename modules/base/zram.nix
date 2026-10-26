_:

{
    flake.modules.nixos.base = {
        # Neither host has a swap partition; compressed swap in RAM instead.
        zramSwap.enable = true;
    };
}
