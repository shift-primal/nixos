{
    stdenvNoCC,
    requireFile,
}:

stdenvNoCC.mkDerivation {
    pname = "circular-std";
    version = "0-unstable-2021-07-29";

    # Personal-use license, so the font stays out of this public repo; add it to
    # the store by hand (befonts.com/circular-std-font.html). Pinned to the .ttf,
    # not the zip: befonts stamps a fresh license file into the zip on every
    # download, so the zip's hash never matches twice.
    src = requireFile {
        name = "circular-std-medium-500.ttf";
        url = "https://befonts.com/circular-std-font.html";
        message = ''
            Download the zip from https://befonts.com/circular-std-font.html, unzip it, then run
              nix-store --add-fixed sha256 circular-std-medium-500.ttf
        '';
        hash = "sha256-qCPYBezoVu7kuidvgkZ2OzEEgN21jb5REvBE9Sr12QA=";
    };

    dontUnpack = true;

    installPhase = ''
        runHook preInstall
        install -Dm644 $src $out/share/fonts/truetype/circular-std-medium-500.ttf
        runHook postInstall
    '';
}
