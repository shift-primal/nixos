_:

{
    flake.modules.homeManager.desktop =
        { lib, pkgs, ... }:
        let

            askpass = pkgs.writeShellScript "sudo-askpass" ''
                exec ${lib.getExe pkgs.zenity} --password --title="sudo"
            '';
        in
        {
            home.sessionVariables.SUDO_ASKPASS = "${askpass}";
        };
}
