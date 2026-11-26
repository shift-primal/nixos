{
    config,
    inputs,
    lib,
    ...
}:

{
    imports = [ inputs.flake-parts.flakeModules.modules ];

    systems = [ "x86_64-linux" ];

    # A piece listed both in a bundle and on a host would otherwise load twice; the key makes the
    # module system load it once.
    _module.args = {
        vars = import ../../vars.nix;
        aspects = lib.mapAttrs (name: module: {
            key = "aspect-${name}";
            imports = [ module ];
        }) config.flake.modules.nixos;
    };
}
