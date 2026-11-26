{
    flake.modules.nixos.keyring = {
        services.gnome = {
            gnome-keyring.enable = true;
            gcr-ssh-agent.enable = false;
        };
        security.pam.services.greetd.enableGnomeKeyring = true;
    };
}
