{ config, inputs, ... }:

let
    inherit (config) vars;
    hm = config.flake.modules.homeManager;
in
{
    # Each NixOS aspect brings its Home Manager twin (flake.modules.homeManager.<aspect>),
    # so hosts only list NixOS aspects. desktop/home.nix does the same.
    flake.modules.nixos.common = {
        imports = [ inputs.home-manager.nixosModules.home-manager ];

        home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.${vars.user.name}.imports = [ hm.common ];
        };
    };

    flake.modules.homeManager.common =
        { osConfig, ... }:
        {
            home = {
                username = vars.user.name;
                homeDirectory = vars.user.home;
                inherit (osConfig.system) stateVersion;
            };

            programs.home-manager.enable = true;
        };
}
