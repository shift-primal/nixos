{ pkgs, ... }:

{
    # Themed boot splash that also asks for the LUKS passphrase (hardware-configuration.nix).
    # The firmware's Lenovo logo stays up with a NixOS spinner under it.
    boot = {
        plymouth = {
            enable = true;
            theme = "nixos-bgrt";
            themePackages = [ pkgs.nixos-bgrt-plymouth ];
        };

        initrd = {
            # Plymouth takes the passphrase through systemd-ask-password. The keymap still comes from
            # console.useXkbConfig (system/core/locale.nix) via systemd-vconsole-setup in the initrd.
            systemd.enable = true;
            # Native panel mode from the start, so the splash doesn't jump when i915 loads later.
            kernelModules = [ "i915" ];
            verbose = false;
        };

        # Keep kernel and systemd messages off the splash.
        consoleLogLevel = 3;
        kernelParams = [
            "quiet"
            "splash"
            "udev.log_level=3"
            "systemd.show_status=auto"
        ];

        # Skip the menu. Hold space during boot to show it and pick an older generation.
        loader.timeout = 0;
    };
}
