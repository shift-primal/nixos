{
    config,
    lib,
    pkgs,
    vars,
    ...
}:

let
    # Fixed flake and actions only, so the sudo rule below doesn't hand out a
    # general nixos-rebuild. The aliases are in dotfiles/zsh/.zshrc.
    rebuild = pkgs.writeShellScriptBin "rebuild" ''
        case "$1" in
            switch|boot) ;;
            *) echo "usage: rebuild switch|boot" >&2; exit 1 ;;
        esac
        exec ${lib.getExe config.system.build.nixos-rebuild} "$1" --flake ${vars.flakeDir}
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
}
