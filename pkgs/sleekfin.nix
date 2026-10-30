{
    lib,
    stdenvNoCC,
    fetchzip,
}:

# SleekFin, a Jellyfin plugin that reskins the web interface (modules/homelab/media/sleekfin.nix).
# The release zip is the plugin folder as Jellyfin's plugin catalog would install it.
stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "jellyfin-plugin-sleekfin";
    version = "1.6.1.0";
    # Its folder name in Jellyfin's plugin folder, before the version (jellyfin.nix).
    passthru.pluginName = "SleekFin";

    src = fetchzip {
        url = "https://github.com/varunaditya-plus/SleekFin/releases/download/${finalAttrs.version}/Jellyfin.Plugin.SleekFin_12.0.0.zip";
        hash = "sha256-Z6WgL/8Tr3ZKbU9eZpJc95KKgV/qk7PUNz0OU3GmtfI=";
        stripRoot = false;
    };

    installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
    '';

    meta = {
        description = "Jellyfin plugin that gives the web interface a modern look";
        homepage = "https://github.com/varunaditya-plus/SleekFin";
        license = lib.licenses.mit;
    };
})
