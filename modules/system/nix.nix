{
    flake.modules.nixos.nix =
        {
            config,
            pkgs,
            inputs,
            vars,
            ...
        }:
        let
            rebuild = pkgs.writeShellApplication {
                name = "rebuild";
                runtimeInputs = [
                    config.nix.package
                    pkgs.gnugrep
                    config.system.build.nixos-rebuild
                ];
                text = ''
                    case "''${1:-}" in
                        switch | boot) ;;
                        *)
                            echo "usage: rebuild switch|boot [host]" >&2
                            exit 1
                            ;;
                    esac
                    host="''${2:-$(< /proc/sys/kernel/hostname)}"

                    hosts="$(nix eval --raw "${vars.flakeDir}#nixosConfigurations" \
                        --apply 'c: builtins.concatStringsSep "\n" (builtins.attrNames c)')"
                    if ! grep -qxF -- "$host" <<< "$hosts"; then
                        echo "rebuild: no nixosConfiguration \"$host\" in ${vars.flakeDir}." >&2
                        echo "Available: ''${hosts//$'\n'/ }" >&2
                        echo "Pick one explicitly: rebuild $1 <host>" >&2
                        exit 1
                    fi

                    exec nixos-rebuild "$1" --flake "${vars.flakeDir}#$host"
                '';
            };
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
                overlays = [
                    inputs.self.overlays.default
                    inputs.luciole.overlays.default
                    inputs.antigravity-nix.overlays.default
                ];
            };

            systemd.tmpfiles.rules = [ "L /etc/nixos - - - - ${vars.flakeDir}" ];

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
