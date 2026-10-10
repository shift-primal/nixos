{ vars, ... }:

{
    imports = [
        ./apps
        ./cli
        ./desktop
        ./dev
        ./shell
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
