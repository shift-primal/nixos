{ pkgs, ... }:

{
    # Boot splash instead of scrolling kernel and systemd output. The firmware logo stays up with a
    # NixOS spinner under it. On the laptop it also asks for the LUKS passphrase.
    boot = {
        plymouth = {
            enable = true;
            theme = "nixos-bgrt";
            themePackages = [ pkgs.nixos-bgrt-plymouth ];
        };

        initrd = {
            # Plymouth starts in the initrd and takes passphrases through systemd-ask-password.
            systemd.enable = true;
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
    };
}
