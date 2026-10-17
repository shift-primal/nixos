{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
    pname = "bagnard";
    version = "0-unstable-2026-03-08";

    src = fetchFromGitHub {
        owner = "sebsan";
        repo = "Bagnard";
        rev = "31415d5e03d2088941fecae2c4ea9f2e6ca0446a";
        hash = "sha256-1ODhlEtV+l/a3z108jCbZ1AEJ0pirg5XVdi1dXxMnlk=";
    };

    installPhase = ''
        runHook preInstall
        install -Dm644 -t $out/share/fonts/opentype Bagnard.otf
        runHook postInstall
    '';
}
