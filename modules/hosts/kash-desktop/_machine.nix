{
    config,
    pkgs,
    vars,
    ...
}:

let
    reboot-to = pkgs.writeShellApplication {
        name = "reboot-to";
        runtimeInputs = [
            pkgs.efibootmgr
            pkgs.gnused
            pkgs.coreutils
            config.systemd.package
        ];
        text = ''
            case "''${1:-}" in
                windows) label="Windows Boot Manager" ;;
                limine) label="Limine" ;;
                *)
                    echo "usage: reboot-to windows|limine" >&2
                    exit 1
                    ;;
            esac
            num=$(efibootmgr | sed -n "s/^Boot\([0-9A-F]\{4\}\)\*\? $label.*/\1/p" | head -n1)
            [ -n "$num" ] || {
                echo "no UEFI entry named '$label'" >&2
                exit 1
            }
            efibootmgr --bootnext "$num" >/dev/null
            systemctl reboot
        '';
    };
in
{
    networking.hostName = "kash-desktop";
    system.stateVersion = "26.05";

    services.xserver.xkb.options = "caps:swapescape";

    boot.loader = {
        systemd-boot.enable = false;
        limine = {
            enable = true;
            maxGenerations = 10;
            extraEntries = ''
                /Windows
                  comment: Windows Boot Manager
                  protocol: efi
                  path: boot():///EFI/Microsoft/Boot/bootmgfw.efi
            '';
        };
    };

    environment.systemPackages = [
        reboot-to
    ]
    ++ (with pkgs; [
        sbctl
        efibootmgr
    ]);

    security.sudo.extraRules = [
        {
            users = [ vars.user.name ];
            commands = [
                {
                    command = "/run/current-system/sw/bin/reboot-to";
                    options = [ "NOPASSWD" ];
                }
            ];
        }
    ];

    hm.systemd.user.services.chatter-log = {
        Unit.Description = "Log keyboard chatter and per-key press totals";
        Service = {
            ExecStart = "${pkgs.python3}/bin/python3 -u ${./chatter-log.py}";
            Restart = "always";
            RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
    };
}
