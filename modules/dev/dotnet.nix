{
    flake.modules.nixos.dotnet =
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
            environment.sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";

            hm.home.packages = [
                dotnet
            ]
            ++ (with pkgs; [
                csharpier
                fantomas
                omnisharp-roslyn
                fsautocomplete
            ]);
        };
}
