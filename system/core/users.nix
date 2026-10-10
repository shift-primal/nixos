{ pkgs, vars, ... }:

{
    # Login shell. Home Manager owns the zsh config (home/shell/zsh.nix), so the
    # system-wide compinit and prompt are turned off.
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
            "docker"
        ];
    };
}
