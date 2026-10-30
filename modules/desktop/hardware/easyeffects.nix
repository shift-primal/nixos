_:

{
    # A user service instead of a Hyprland exec, so systemd restarts it when it dies.
    # The preset itself lives in ~/.local/share/easyeffects and is edited from the GUI.
    flake.modules.homeManager.desktop.services.easyeffects = {
        enable = true;
        preset.input = "Kasper";
    };
}
