{ lib, pkgs, vars, ... }:

let
    # Only these two fixed targets can be requested, so the sudo rule below
    # doesn't hand out a general efibootmgr.
    reboot-to = pkgs.writeShellScriptBin "reboot-to" ''
        case "$1" in
            windows) label="Windows Boot Manager" ;;
            limine)  label="Limine" ;;
            *) echo "usage: reboot-to windows|limine" >&2; exit 1 ;;
        esac
        num=$(${lib.getExe pkgs.efibootmgr} | ${lib.getExe pkgs.gnused} -n "s/^Boot\([0-9A-F]\{4\}\)\*\? $label.*/\1/p" | head -n1)
        [ -n "$num" ] || { echo "no UEFI entry named '$label'" >&2; exit 1; }
        ${lib.getExe pkgs.efibootmgr} --bootnext "$num" >/dev/null
        systemctl reboot
    '';
in
{
    environment.systemPackages = [ reboot-to ];

    # Used by the Noctalia power menu; run as `sudo reboot-to windows`.
    security.sudo.extraRules = [{
        users = [ vars.user.name ];
        commands = [{
            command = "/run/current-system/sw/bin/reboot-to";
            options = [ "NOPASSWD" ];
        }];
    }];
}
