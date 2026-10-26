{
    lib,
    buildGoModule,
    fetchFromGitHub,
    fuse3,
}:

buildGoModule (finalAttrs: {
    pname = "decypharr";
    version = "2.7.1";

    src = fetchFromGitHub {
        owner = "sirrobot01";
        repo = "decypharr";
        tag = "v${finalAttrs.version}";
        hash = "sha256-6CVk2WzXU79Sb5drUFLE6Pyecnh55YqPw7ZJKPHXiEo=";
    };

    vendorHash = "sha256-Uo5mjyKsTz0d71pxb7t/7ClgUuRyU4M2eWYjS+qzYCw=";

    # The FUSE mount (DFS, through cgofuse) and the yEnc decoder use cgo. cgofuse hard-codes
    # /usr/include/fuse3 and opens libfuse3 with dlopen at runtime, hence the include path and rpath.
    env.CGO_ENABLED = 1;
    env.NIX_CFLAGS_COMPILE = "-I${lib.getDev fuse3}/include/fuse3";
    tags = [ "fuse3" ];
    buildInputs = [ fuse3 ];
    postFixup = ''
        patchelf --add-rpath ${lib.getLib fuse3}/lib $out/bin/decypharr
    '';

    subPackages = [ "." ];
    ldflags = [
        "-s"
        "-w"
        "-X github.com/sirrobot01/decypharr/pkg/version.Version=${finalAttrs.version}"
        "-X github.com/sirrobot01/decypharr/pkg/version.Channel=stable"
    ];

    meta = {
        description = "Debrid client that poses as qBittorrent for Sonarr and Radarr and mounts the debrid library";
        homepage = "https://github.com/sirrobot01/decypharr";
        license = lib.licenses.mit;
        mainProgram = "decypharr";
    };
})
