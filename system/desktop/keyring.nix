_:

{
    # Secret Service for apps that keep credentials in the OS keyring. Bitwarden needs it to keep
    # the vault unlocked across reboots with the "Never" timeout; without it the key is dropped.
    services.gnome.gnome-keyring.enable = true;

    # Bitwarden is the SSH agent (SSH_AUTH_SOCK in home/shell/zsh.nix); keep gcr from claiming it.
    services.gnome.gcr-ssh-agent.enable = false;

    # Unlock the keyring with the password typed at the greeter (system/desktop/greeter.nix), so
    # it never asks for its own.
    security.pam.services.greetd.enableGnomeKeyring = true;
}
