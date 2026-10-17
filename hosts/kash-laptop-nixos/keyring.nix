{ vars, ... }:

{
    # Autologin (greetd.nix) types no password, so PAM can't unlock the keyring from
    # system/desktop/keyring.nix and it would prompt every boot. Seed an unencrypted login
    # keyring instead: the LUKS passphrase already guards the disk.
    home-manager.users.${vars.user.name} =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            # Plaintext keyring header, as read by gnome-keyring's gkm-secret-textual.c.
            emptyKeyring = pkgs.writeText "login.keyring" ''
                [keyring]
                display-name=Login
                ctime=0
                mtime=0
                lock-on-idle=false
                lock-timeout=0
            '';
        in
        {
            # Copied, not linked: gnome-keyring rewrites the file as secrets are stored. An existing
            # keyring is left alone so stored secrets are never wiped.
            home.activation.seedLoginKeyring = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                keyrings="${config.xdg.dataHome}/keyrings"
                if [ ! -e "$keyrings/login.keyring" ]; then
                    run mkdir -p -m 700 "$keyrings"
                    run install -m 600 ${emptyKeyring} "$keyrings/login.keyring"
                    [ -e "$keyrings/default" ] || run sh -c "echo login > '$keyrings/default'"
                fi
            '';
        };
}
