{
    symlinkJoin,
    makeWrapper,
    nixfmt,
}:

symlinkJoin {
    name = "nixfmt";
    paths = [ nixfmt ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
        wrapProgram $out/bin/nixfmt --add-flags "--width=100 --indent=4"
    '';
    meta.mainProgram = "nixfmt";
}
