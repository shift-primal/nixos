_:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                lua-language-server
                stylua
            ];
        };
}
