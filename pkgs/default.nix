final: prev: {
    nixfmt-wrapped = final.callPackage ./nixfmt.nix { };
    oxfmt = final.callPackage ./oxfmt.nix { inherit (prev) oxfmt; };
}
