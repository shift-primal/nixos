_:

{
    flake.modules.nixos.kash-laptop-nixos = {
        # The splash itself is modules/workstation/plymouth.nix. The LUKS keymap comes from console.useXkbConfig
        # (modules/base/locale.nix) via systemd-vconsole-setup in the initrd.
        boot = {
            # Native panel mode from the start, so the splash doesn't jump when i915 loads later.
            initrd.kernelModules = [ "i915" ];

            # Skip the menu. Hold space during boot to show it and pick an older generation.
            loader.timeout = 0;
        };
    };
}
