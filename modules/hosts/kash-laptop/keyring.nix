{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.kash-laptop = {

        home-manager.users.${vars.user.name} =
            {
                config,
                lib,
                pkgs,
                ...
            }:
            let

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

                home.activation.seedLoginKeyring = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    keyrings="${config.xdg.dataHome}/keyrings"
                    if [ ! -e "$keyrings/login.keyring" ]; then
                        run mkdir -p -m 700 "$keyrings"
                        run install -m 600 ${emptyKeyring} "$keyrings/login.keyring"
                        [ -e "$keyrings/default" ] || run sh -c "echo login > '$keyrings/default'"
                    fi
                '';
            };
    };
}
