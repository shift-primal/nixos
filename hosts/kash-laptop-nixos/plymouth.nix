_:

{
    # The splash itself is system/core/plymouth.nix. The LUKS keymap comes from console.useXkbConfig
    # (system/core/locale.nix) via systemd-vconsole-setup in the initrd.
    boot = {
        # Native panel mode from the start, so the splash doesn't jump when i915 loads later.
        initrd.kernelModules = [ "i915" ];

        # Skip the menu. Hold space during boot to show it and pick an older generation.
        loader.timeout = 0;
    };
}
