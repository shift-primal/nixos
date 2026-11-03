_:

{
    flake.modules.nixos.desktop = {

        services.gnome.gnome-keyring.enable = true;

        services.gnome.gcr-ssh-agent.enable = false;

        security.pam.services.greetd.enableGnomeKeyring = true;
    };
}
