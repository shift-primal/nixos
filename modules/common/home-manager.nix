{ config, inputs, ... }:

let
    inherit (config) vars;
    hm = config.flake.modules.homeManager;
in
{

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
