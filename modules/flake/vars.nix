#

{ lib, ... }:

{
    options.vars = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        description = "Values shared by modules and dotfiles.";
    };

    config.vars = rec {
        user = {
            name = "kasper";
            fullName = "Kasper Haugestøl";
            home = "/home/${user.name}";

            sshKeys = {
                personal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKCQ78itQutj3zwTn6g+2RwSi8zl7+mssOGsQyeekZB kash-ssh-key";
                kash-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOi/1l6nA7bR2D13n/Te5Xk6E/VIUcp/+CSTMOD8CTve kash-desktop";
                kash-laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHnIGFPN6Pc6pS34mlIJ3suQp8wZ6YTa6b9PdoHDLTqX kash-laptop";
            };
        };

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
