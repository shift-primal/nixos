final: prev: {
    oxfmt = final.callPackage ./oxfmt.nix { inherit (prev) oxfmt; };
}
