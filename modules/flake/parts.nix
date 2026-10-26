{ inputs, ... }:

{
    # Adds flake.modules.<class>.<aspect>: every file can add to an aspect, and the
    # definitions merge. Hosts import aspects from there (modules/hosts/).
    imports = [ inputs.flake-parts.flakeModules.modules ];

    systems = [ "x86_64-linux" ];
}
