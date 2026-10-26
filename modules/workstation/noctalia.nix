{ inputs, ... }:

{
    flake.modules.homeManager.workstation = {
        imports = [ inputs.noctalia.homeModules.default ];

        programs.noctalia.enable = true;
    };
}
