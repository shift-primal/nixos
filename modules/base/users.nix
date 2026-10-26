{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.base =
        { pkgs, ... }:
        {
            # Login shell. Home Manager owns the zsh config (modules/base/shell/zsh.nix), so the
            # system-wide compinit and prompt are turned off.
            programs.zsh = {
                enable = true;
                enableGlobalCompInit = false;
                promptInit = "";
            };

            # Features that need a group add it themselves (docker.nix, wireshark.nix, i2c.nix).
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
            };
        };
}
