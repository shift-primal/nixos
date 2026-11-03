{
    lib,
    stdenvNoCC,
    fetchzip,
    writeText,
}:

let

    jellyfinVersion = "12.2.0";
in

stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "jellyfin-plugin-file-transformation";
    version = "3.0.2.0";

    passthru.pluginName = "File Transformation";

    src = fetchzip {
        url = "https://github.com/IAmParadox27/jellyfin-plugin-file-transformation/releases/download/${finalAttrs.version}/Release-${jellyfinVersion}.zip";
        hash = "sha256-YufVExHm9nC7yaSXAO7Z5f4mTbxRJ1y3rhWC4IwG0KE=";
        stripRoot = false;
    };

    meta_json = writeText "meta.json" (
        builtins.toJSON {
            guid = "5e87cc92-571a-4d8d-8d98-d2d4147f9f90";
            name = finalAttrs.passthru.pluginName;
            inherit (finalAttrs) version;
            targetAbi = "${jellyfinVersion}.0";
            assemblies = [ "Jellyfin.Plugin.FileTransformation.dll" ];
            status = "Active";
            autoUpdate = false;
            category = "General";
            owner = "IAmParadox27";
        }
    );

    installPhase = ''
        runHook preInstall
        cp -r . $out
        cp $meta_json $out/meta.json
        runHook postInstall
    '';

    meta = {
        description = "Jellyfin plugin that lets other plugins change the web interface's files";
        homepage = "https://github.com/IAmParadox27/jellyfin-plugin-file-transformation";
        license = lib.licenses.gpl3Only;
    };
})
