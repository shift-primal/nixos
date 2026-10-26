{
    lib,
    stdenvNoCC,
    fetchzip,
}:

# Gelato, the Jellyfin plugin that streams Stremio addons (modules/server/media/gelato.nix). The
# release zip is the plugin folder as Jellyfin's plugin catalog would install it.
stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "jellyfin-plugin-gelato";
    version = "0.26.29.0";

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
