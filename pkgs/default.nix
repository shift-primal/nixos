# Overlay with packages that are not in nixpkgs, or newer than its version. One file per package.
final: prev: {
    bagnard = final.callPackage ./bagnard.nix { };
    circular-std = final.callPackage ./circular-std.nix { };
    cutover = final.callPackage ./cutover.nix { };
    grok-cli = final.callPackage ./grok.nix { };
    jellyfin-plugin-file-transformation = final.callPackage ./jellyfin-file-transformation.nix { };
    jellyfin-plugin-gelato = final.callPackage ./gelato.nix { };
    jellyfin-plugin-sleekfin = final.callPackage ./sleekfin.nix { };
    oxfmt = final.callPackage ./oxfmt.nix { inherit (prev) oxfmt; };
}
