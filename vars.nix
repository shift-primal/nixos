rec {
    user = {
        name = "kasper";
        fullName = "Kasper Haugestøl";
        home = "/home/${user.name}";

        sshKeys = {
            personal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKCQ78itQutj3zwTn6g+2RwSi8zl7+mssOGsQyeekZB kash-ssh-key";
        };
    };

    flakeDir = "${user.home}/nixos";

    hosts = [
        "kash-desktop"
        "kash-laptop"
        "kash-homelab"
    ];

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
}
