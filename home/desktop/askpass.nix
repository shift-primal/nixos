{ lib, pkgs, ... }:

let
    # sudo runs this when it has no terminal (e.g. Claude Code's `!` commands) and prints the
    # password it outputs. Cancelling exits non-zero, which sudo treats as a failed attempt.
    askpass = pkgs.writeShellScript "sudo-askpass" ''
        exec ${lib.getExe pkgs.zenity} --password --title="sudo"
    '';
in
{
    home.sessionVariables.SUDO_ASKPASS = "${askpass}";
}
