{
    # Rider starts from the launcher, outside any project's direnv shell, so it needs an SDK on the
    # session PATH to find MSBuild. Without one it offers to download Microsoft's build into
    # ~/.dotnet, which fails on NixOS (no libicu). A project's dev shell (templates/dotnet) still
    # comes first on PATH inside the project.
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
            # Lets apphosts (bin/Debug/.../<Project>) find the runtime when Rider runs them.
            environment.sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";
        };

    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.jetbrains.rider ];
        };
}
