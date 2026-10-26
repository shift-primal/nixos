_:

{
    flake.modules.homeManager.workstation =
        { pkgs, ... }:
        {
            # Started from dotfiles/hypr/hyprland/autostart.lua.
            home.packages = with pkgs; [
                wl-clipboard
                cliphist
                wl-clip-persist
            ];
        };
}
