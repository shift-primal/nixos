final: prev: {
    nixfmt-wrapped = final.callPackage ./nixfmt.nix { };
    oxfmt = final.callPackage ./oxfmt.nix { inherit (prev) oxfmt; };
    hypr-autoscroll = final.callPackage ./hypr-autoscroll.nix { };
}
