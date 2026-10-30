_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                nil
                nixfmt
                treefmt
                statix
            ];
        };
}
