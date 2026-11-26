{
    flake.modules.nixos.general-apps =
        { pkgs, inputs, ... }:
        {
            imports = [ inputs.artcraft.nixosModules.default ];

            programs.artcraft = {
                enable = true;
                apps = [
                    "photocraft"
                    "vectorcraft"
                ];
            };

            hm.home.packages = with pkgs; [
                filezilla
                vlc
                mpv
                (onlyoffice-desktopeditors.override { extraFontPackages = [ corefonts ]; })
            ];
        };
}
