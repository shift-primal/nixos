{
    stdenvNoCC,
    requireFile,
    unzip,
}:

stdenvNoCC.mkDerivation {
    pname = "circular-std";
    version = "0-unstable-2021-07-29";

    # Personal-use license, so the font stays out of this public repo; add the
    # zip to the store by hand (befonts.com/circular-std-font.html).
    src = requireFile {
        name = "circular-std-font.zip";
        url = "https://befonts.com/circular-std-font.html";
        hash = "sha256-qoPGONFqrA4DAfvsxHHrRgyq0JuwG7WVDk/jiXF5h5k=";
    };

    nativeBuildInputs = [ unzip ];
    sourceRoot = ".";

    installPhase = ''
        runHook preInstall
        install -Dm644 -t $out/share/fonts/truetype *.ttf
        runHook postInstall
    '';
}
