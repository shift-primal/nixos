# Single source of truth for values used by more than one module, or by the
# live-edited dotfiles. Changing a value here needs a rebuild; editing a file
# under dotfiles/ does not.
#
# Modules read these as config.vars of the flake-parts module around them. Dotfiles read
# them through ~/.config/nixos-vars/vars.lua (modules/workstation/vars-lua.nix).
{ lib, ... }:

{
    options.vars = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        description = "Values shared by modules and dotfiles.";
    };

    # hostname and stateVersion are per machine: set in modules/hosts/<hostname>/default.nix.
    config.vars = rec {
        user = {
            name = "kasper";
            fullName = "Kasper Haugestøl";
            home = "/home/${user.name}";
            # Public SSH keys authorized on every machine (modules/base/openssh.nix). The private
            # halves live in Bitwarden and are served by its SSH agent (SSH_AUTH_SOCK in
            # modules/base/shell/zsh.nix). The homelab has no key: nothing SSHes out from it.
            sshKeys = {
                personal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKCQ78itQutj3zwTn6g+2RwSi8zl7+mssOGsQyeekZB kash-ssh-key";
                kash-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOi/1l6nA7bR2D13n/Te5Xk6E/VIUcp/+CSTMOD8CTve kash-desktop";
                kash-laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHnIGFPN6Pc6pS34mlIJ3suQp8wZ6YTa6b9PdoHDLTqX kash-laptop";
            };
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
        # modules/workstation/default-apps.nix and its command is handed to the Hyprland keybinds.
        apps = {
            terminal = "kitty";
            editor = "neovim";
            sysmonitor = "btop";
            explorer = "yazi";
            browser = "google-chrome";
            discord = "vesktop";
            email = "thunderbird";
            spotify = "spotatui";
        };
    };
}
