{ lib, pkgs, ... }:

{
    # gcc keeps cc and ld; clang has a higher priority number (lower precedence) so the wrappers' shared binaries don't collide.
    home.packages = [
        pkgs.gcc
        (lib.setPrio 15 pkgs.clang)
    ];
}
