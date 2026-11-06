{
    lib,
    fetchFromGitHub,
    cmake,
    hyprlandPlugins,
}:

hyprlandPlugins.mkHyprlandPlugin {
    pluginName = "hypr-autoscroll";
    version = "0.3.2-unstable-2026-10-19";

    src = fetchFromGitHub {
        owner = "estebanhiram";
        repo = "hypr-autoscroll";
        rev = "dcb9c8fd85a96c52ec87ccd69c88def83315e9d4";
        hash = "sha256-8qgXLf33BXe1VuJO1fXo+PR4Uxl18JljLMs4FlmKeEA=";
    };

    # Upstream supports Hyprland up to 0.56; drop once it builds against 0.57 unpatched.
    patches = [ ./hypr-autoscroll-hyprland-0.57.patch ];

    nativeBuildInputs = [ cmake ];

    meta = {
        homepage = "https://github.com/estebanhiram/hypr-autoscroll";
        description = "Windows-style middle-click autoscrolling for Hyprland";
        license = lib.licenses.bsd3;
    };
}
