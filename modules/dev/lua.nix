_:

{
    flake.modules.homeManager.dev =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                lua-language-server
                stylua
            ];
        };
}
