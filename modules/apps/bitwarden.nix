{
    flake.modules.nixos.bitwarden =
        { lib, pkgs, ... }:
        {
            hm = {
                home.packages = with pkgs; [
                    bitwarden-desktop
                    rbw
                    bitwarden-cli
                    bws
                ];

                systemd.user.services.bitwarden = {
                    Unit = {
                        Description = "Bitwarden (SSH agent)";
                        PartOf = [ "graphical-session.target" ];
                        After = [ "graphical-session.target" ];
                    };
                    Service = {
                        ExecStart = lib.getExe pkgs.bitwarden-desktop;
                        Restart = "on-failure";
                        RestartSec = 3;
                    };
                    Install.WantedBy = [ "graphical-session.target" ];
                };

                programs.zsh.sessionVariables.SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
            };
        };
}
