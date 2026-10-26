_:

{
    flake.modules.homeManager.dev =
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
