{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.base = {
        time.timeZone = vars.timeZone;
        i18n.defaultLocale = vars.locale;

        services.xserver.xkb = {
            inherit (vars.keyboard) layout variant;
        };

        # Builds the console keymap from the xkb layout above.
        console.useXkbConfig = true;
    };
}
