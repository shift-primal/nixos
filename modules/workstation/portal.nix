_:

{
    flake.modules.nixos.workstation =
        { pkgs, ... }:
        {
            xdg.portal = {
                enable = true;
                extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
            };
        };
}
