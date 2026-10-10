{ ... }:
{
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "no";
    variant = "nodeadkeys";
  };

  console.keyMap = "no";
}
