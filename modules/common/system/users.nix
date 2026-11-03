{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.common =
        { pkgs, ... }:
        {

            programs.zsh = {
                enable = true;
                enableGlobalCompInit = false;
                promptInit = "";
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
            };
        };
}
