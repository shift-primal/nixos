# Overlay with packages that are not in nixpkgs. One file per package.
final: _prev: {
    bagnard = final.callPackage ./bagnard.nix { };
    circular-std = final.callPackage ./circular-std.nix { };
    grok-cli = final.callPackage ./grok.nix { };
}
