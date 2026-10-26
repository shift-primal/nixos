{ config, inputs, ... }:

let
    inherit (config) vars;
    hm = config.flake.modules.homeManager;
in
{
    # Each NixOS aspect brings its Home Manager twin (flake.modules.homeManager.<aspect>),
    # so hosts only list NixOS aspects. workstation/home.nix and dev/home.nix do the same.
    flake.modules.nixos.base = {
        imports = [ inputs.home-manager.nixosModules.home-manager ];

        home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.${vars.user.name}.imports = [ hm.base ];
        };
    };

    flake.modules.homeManager.base =
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
