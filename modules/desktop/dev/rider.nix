{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.jetbrains.rider ];
        };
}
