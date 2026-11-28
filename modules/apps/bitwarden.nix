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
                        ExecStartPost = pkgs.writeShellScript "bitwarden-close-window" ''
                            export PATH=${
                                lib.makeBinPath [
                                    pkgs.niri
                                    pkgs.jq
                                ]
                            }:$PATH
                            (
                            for _ in $(seq 60); do
                                id=$(niri msg --json windows | jq -r '[.[] | select(.app_id == "bitwarden")][0].id // empty')
                                if [ -n "$id" ]; then
                                    niri msg action close-window --id "$id"
                                    exit 0
                                fi
                                sleep 0.5
                            done
                            ) &
                        '';
                        Restart = "on-failure";
                        RestartSec = 3;
                    };
                    Install.WantedBy = [ "graphical-session.target" ];
                };

                programs.zsh.sessionVariables.SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
            };
        };
}
