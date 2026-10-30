_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                rustc
                cargo
                rustfmt
                clippy
            ];
        };
}
