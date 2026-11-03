_:

{
    # niri reads this through vars.kdl (modules/desktop/session/niri.nix); the console keymap follows
    # too. Hyprland sets the same in dotfiles/hypr/hyprland/hosts/kash-laptop.lua.
    flake.modules.nixos.kash-laptop.services.xserver.xkb.options = "caps:swapescape";
}
