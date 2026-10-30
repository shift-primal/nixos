_:

{
    flake.modules.nixos.desktop =
        { pkgs, ... }:
        {
            xdg.portal = {
                enable = true;
                extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
            };
        };
}
