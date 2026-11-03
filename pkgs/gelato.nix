{
    lib,
    stdenvNoCC,
    fetchzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "jellyfin-plugin-gelato";
    version = "0.26.29.0";

    passthru.pluginName = "Gelato";

    src = fetchzip {
        url = "https://github.com/lostb1t/Gelato/releases/download/v${finalAttrs.version}/gelato_${finalAttrs.version}.zip";
        hash = "sha256-927Bmi7EnFXE/NmOd5UzruxIZTtcrNeGOVITLJIqgHQ=";
        stripRoot = false;
    };

    installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
    '';

    meta = {
        description = "Jellyfin plugin that brings Stremio addons (AIOStreams) into the library";
        homepage = "https://github.com/lostb1t/Gelato";
        license = lib.licenses.gpl3Only;
    };
})
