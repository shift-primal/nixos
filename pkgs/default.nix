# Overlay with packages that are not in nixpkgs, or newer than its version. One file per package.
final: prev: {
    bagnard = final.callPackage ./bagnard.nix { };
    circular-std = final.callPackage ./circular-std.nix { };
    cutover = final.callPackage ./cutover.nix { };
    decypharr = final.callPackage ./decypharr.nix { };
    grok-cli = final.callPackage ./grok.nix { };
    jellyfin-plugin-gelato = final.callPackage ./gelato.nix { };
    oxfmt = final.callPackage ./oxfmt.nix { inherit (prev) oxfmt; };
}
