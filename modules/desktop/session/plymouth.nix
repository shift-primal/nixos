_:

{
    flake.modules.nixos.desktop =
        { pkgs, ... }:
        {

            boot = {
                plymouth = {
                    enable = true;
                    theme = "nixos-bgrt";
                    themePackages = [ pkgs.nixos-bgrt-plymouth ];
                };

                consoleLogLevel = 3;
                kernelParams = [
                    "quiet"
                    "splash"
                    "udev.log_level=3"
                    "systemd.show_status=auto"
                ];
            };
        };
}
