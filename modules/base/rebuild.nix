{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.base =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            # Fixed flake and actions only, so the sudo rule below doesn't hand out a
            # general nixos-rebuild. The aliases are in dotfiles/zsh/.zshrc.
            # The host is the current hostname, or the optional second argument for when the
            # hostname doesn't match a config yet (a fresh install or a rename).
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
