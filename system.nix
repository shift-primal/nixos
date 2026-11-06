{
    config,
    lib,
    pkgs,
    inputs,
    vars,
    ...
}:

let
    rebuild = pkgs.writeShellScriptBin "rebuild" ''
        set -euo pipefail
        case "''${1:-}" in
            switch|boot) ;;
            *) echo "usage: rebuild switch|boot [host]" >&2; exit 1 ;;
        esac
        host="''${2:-$(< /proc/sys/kernel/hostname)}"

        hosts="$(${lib.getExe config.nix.package} eval --raw ${vars.flakeDir}#nixosConfigurations \
            --apply 'c: builtins.concatStringsSep "\n" (builtins.attrNames c)')"
        if ! grep -qxF -- "$host" <<< "$hosts"; then
            echo "rebuild: no nixosConfiguration \"$host\" in ${vars.flakeDir}." >&2
            echo "Available: ''${hosts//$'\n'/ }" >&2
            echo "Pick one explicitly: rebuild $1 <host>" >&2
            exit 1
        fi

        exec ${lib.getExe config.system.build.nixos-rebuild} "$1" --flake "${vars.flakeDir}#$host"
    '';
in
{
    nix = {
        settings.experimental-features = [
            "nix-command"
            "flakes"
        ];

        gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
        };
    };

    nixpkgs = {
        config.allowUnfree = true;
        overlays = [ inputs.self.overlays.default ];
    };

    systemd.tmpfiles.rules = [ "L /etc/nixos - - - - ${vars.flakeDir}" ];

    environment.systemPackages = [
        rebuild
        pkgs.kitty.terminfo
    ];

    security.sudo.extraRules = [
        {
            users = [ vars.user.name ];
            commands = [
                {
                    command = "/run/current-system/sw/bin/rebuild";
                    options = [ "NOPASSWD" ];
                }
            ];
        }
    ];

    boot = {
        loader.efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot";
        };
        supportedFilesystems = [ "ntfs" ];
        kernelPackages = pkgs.linuxPackages_latest;
    };

    time.timeZone = vars.timeZone;
    i18n.defaultLocale = vars.locale;
    services = {
        xserver.xkb = {
            inherit (vars.keyboard) layout variant;
        };
        fwupd.enable = true;
        tailscale.enable = true;

        openssh = {
            enable = true;
            openFirewall = false;
            settings = {
                PasswordAuthentication = false;
                KbdInteractiveAuthentication = false;
                PermitRootLogin = "no";
            };
        };
    };
    console.useXkbConfig = true;

    zramSwap.enable = true;
    programs = {

        zsh = {
            enable = true;
            enableGlobalCompInit = false;
            promptInit = "";
        };

        ssh.systemd-ssh-proxy.enable = false;
        ssh.extraConfig = lib.concatMapStrings (host: ''
            Host ${lib.removePrefix "kash-" host}
                HostName ${host}
        '') vars.hosts;

        nix-ld = {
            enable = true;
            libraries = with pkgs; [
                alsa-lib
                at-spi2-atk
                at-spi2-core
                cairo
                cups
                dbus
                expat
                glib
                libdrm
                libgbm
                libxkbcommon
                nspr
                nss
                pango
                systemd
                libx11
                libxcb
                libxcomposite
                libxdamage
                libxext
                libxfixes
                libxrandr
            ];
        };
    };

    users.users.${vars.user.name} = {
        isNormalUser = true;
        description = vars.user.fullName;
        home = vars.user.home;
        shell = pkgs.zsh;
        extraGroups = [
            "networkmanager"
            "wheel"
            "video"
            "render"
            "input"
        ];
        openssh.authorizedKeys.keys = lib.attrValues vars.user.sshKeys;
    };

    networking.networkmanager.enable = true;
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
