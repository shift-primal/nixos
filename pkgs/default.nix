# Overlay with packages that are not in nixpkgs. One file per package.
final: _prev: {
    grok-cli = final.callPackage ./grok.nix { };
}
