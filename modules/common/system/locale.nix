{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.common = {
        time.timeZone = vars.timeZone;
        i18n.defaultLocale = vars.locale;

        services.xserver.xkb = {
            inherit (vars.keyboard) layout variant;
        };

        console.useXkbConfig = true;
    };
}
