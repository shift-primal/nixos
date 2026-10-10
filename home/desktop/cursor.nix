{ pkgs, vars, ... }:

{
    # Hyprland reads the same name and size from vars.lua (hyprland/cursor.lua).
    home.pointerCursor = {
        enable = true;
        package = pkgs.${vars.cursor.package};
        inherit (vars.cursor) name size;
        gtk.enable = true;
        x11.enable = true;
    };
}
