{
    flake.modules.nixos.users =
        {
            config,
            lib,
            inputs,
            vars,
            ...
        }:
        {
            imports = [
                inputs.home-manager.nixosModules.home-manager
                (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" vars.user.name ])
            ];

            _module.args.link =
                path: config.hm.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/${path}";

            users.users.${vars.user.name} = {
                isNormalUser = true;
                description = vars.user.fullName;
                home = vars.user.home;
                extraGroups = [
                    "networkmanager"
                    "wheel"
                    "video"
                    "render"
                    "input"
                ];
                openssh.authorizedKeys.keys = lib.attrValues vars.user.sshKeys;
            };

            home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
            };

            hm.home = {
                username = vars.user.name;
                homeDirectory = vars.user.home;
                inherit (config.system) stateVersion;
            };
        };
}
