{
    flake.modules.nixos.luciole =
        { inputs, ... }:
        {
            hm = {
                imports = [ inputs.luciole.homeModules.default ];
                programs.luciole.enable = true;
            };
        };
}
