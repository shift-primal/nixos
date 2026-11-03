{ inputs, ... }:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {

            home.packages = [
                inputs.ai-usagebar.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];
        };
}
