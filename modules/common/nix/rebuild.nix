{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.common =
        {
            config,
            lib,
            pkgs,
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
            environment.systemPackages = [ rebuild ];

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
        };
}
