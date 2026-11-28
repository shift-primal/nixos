{ aspects, ... }:

{
    flake.modules.nixos = with aspects; {
        system.imports = [
            nix
            boot
            locale
            users
            network
            ssh
        ];

        hardware.imports = [
            audio
            printing
            peripherals
        ];

        desktop.imports = [
            hyprland
            niri
            wayland-tools
            noctalia
            keyring
            theme
            fonts
            session
            splash
            kitty
            luciole
            default-apps
        ];

        shell.imports = [
            zsh
            git
            shell-plugins
            cli-tools
        ];

        dev.imports = [
            docker
            wireshark
            jetbrains
            dotnet
            web
            languages
            cloud
            config-tools
            neovim
            nix-ld
        ];

        apps.imports = [
            ai
            bitwarden
            general-apps
            gaming
        ];
    };
}
