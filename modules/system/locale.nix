{
    flake.modules.nixos.locale =
        { vars, ... }:
        {
            time.timeZone = vars.timeZone;
            i18n.defaultLocale = vars.locale;

            services.xserver.xkb = {
                inherit (vars.keyboard) layout variant;
            };
            console.useXkbConfig = true;
        };
}
