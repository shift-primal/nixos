# Single source of truth for values used by more than one module, or by the
# live-edited dotfiles. Changing a value here needs a rebuild; editing a file
# under dotfiles/ does not.
#
# Dotfiles read these through ~/.config/nixos-vars/vars.lua (home/vars-lua.nix).
rec {
    # hostname and stateVersion are per machine: see hosts/<hostname>/vars.nix.

    user = {
        name = "kasper";
        fullName = "Kasper Haugestøl";
        home = "/home/${user.name}";
    };

    # /etc/nixos links here. Dotfiles are linked out of the store from dotfiles/.
    flakeDir = "${user.home}/nixos";

    timeZone = "Europe/Oslo";
    locale = "en_US.UTF-8";

    keyboard = {
        layout = "no";
        variant = "nodeadkeys";
    };

    cursor = {
        package = "bibata-cursors";
        name = "Bibata-Modern-Classic";
        size = 24;
    };

    # Default apps, as nixpkgs attribute names. Each one is installed by
    # home/apps/defaults.nix and its command is handed to the Hyprland keybinds.
    apps = {
        terminal = "kitty";
        editor = "neovim";
        sysmonitor = "btop";
        explorer = "yazi";
        browser = "firefox";
        discord = "vesktop";
        email = "thunderbird";
        spotify = "spotatui";
    };
}
