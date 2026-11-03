_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                nil
                statix
            ];
        };
}
