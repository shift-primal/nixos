{ vars, ... }:

{
    imports = [
        ./apps
        ./cli
        ./desktop
        ./dev
        ./shell
        ./claude-skills.nix
        ./dotfiles.nix
        ./vars-lua.nix
    ];

    home = {
        username = vars.user.name;
        homeDirectory = vars.user.home;
        inherit (vars) stateVersion;
    };

    programs.home-manager.enable = true;
}
