{ inputs, ... }:

{
    flake.modules.homeManager.desktop = {
        imports = [ inputs.noctalia.homeModules.default ];

        programs.noctalia.enable = true;
    };
}
