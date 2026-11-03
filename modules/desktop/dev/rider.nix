{
    flake.modules.nixos.desktop =
        { pkgs, ... }:
        let
            dotnet = pkgs.dotnetCorePackages.combinePackages (
                with pkgs.dotnetCorePackages;
                [
                    sdk_8_0
                    sdk_9_0
                    sdk_10_0
                ]
            );
        in
        {
            environment.systemPackages = [ dotnet ];
            environment.sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";
        };

    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.jetbrains.rider ];
        };
}
