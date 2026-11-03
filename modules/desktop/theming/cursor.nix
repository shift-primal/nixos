{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {

            home.pointerCursor = {
                enable = true;
                package = pkgs.${vars.cursor.package};
                inherit (vars.cursor) name size;
                gtk.enable = true;
                x11.enable = true;
            };
        };
}
