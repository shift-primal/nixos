# nixpkgs' oxfmt (0.68) can't format .astro. Newer oxfmt can, but only with @astrojs/compiler-rs
# next to it, which oxfmt doesn't bundle and nixpkgs doesn't package; ship it in node_modules.
# Drop the version bump once nixpkgs catches up.
{
    lib,
    stdenv,
    fetchFromGitHub,
    fetchPnpmDeps,
    fetchurl,
    autoPatchelfHook,
    pnpm_10,
    rustPlatform,
    oxfmt,
}:

let
    npmTarball =
        name: hash:
        fetchurl {
            url = "https://registry.npmjs.org/@astrojs/${name}/-/${name}-0.5.2.tgz";
            inherit hash;
        };

    # compiler-rs loads compiler-binding, which loads the native module for this platform
    astro = lib.mapAttrs npmTarball {
        compiler-rs = "sha512-IvwYLB8t1M86rKO4oPdBi9GP4gzXcgrVlNgocjwos1jeeUuEIV8d9Crn1PvYD/5IKteWOxpIHomf7e8iYlkE+Q==";
        compiler-binding = "sha512-lEn76+0JcMQ5RDXU0wSMWJg2ZppiZvSULpghC29cfv4o9bhvWFDbQjsCtvjjXN9iVLFQ7fL3wTR2L2UU13mP8g==";
        compiler-binding-linux-x64-gnu = "sha512-9XAqGTMQAtIslMsjK3xdyY6OI9d59OZqcLBB6pvD/DcoR0daYswfrKx2azdDERDY4AqAnWPC7odVM1BmxYv3Vw==";
    };
in
oxfmt.overrideAttrs (
    finalAttrs: prev: {
        version = "0.74.0";

        src = fetchFromGitHub {
            owner = "oxc-project";
            repo = "oxc";
            tag = "oxfmt_v${finalAttrs.version}";
            hash = "sha256-hXVly6d7iiW/7vQJxqM+X6jvS1dQEinMCCbJG8M9vuw=";
        };

        cargoDeps = rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) pname version src;
            hash = "sha256-4XhNEVojZ9eG9cILG/XTgW9HGalLWIgZ4jkh1ZOX42g=";
        };

        pnpmDeps = fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            pnpm = pnpm_10;
            fetcherVersion = 3;
            hash = "sha256-U/CuxR2+zQJAaegcqGc3n7hgZ/RRBpRCNgYfa9pOr0g=";
        };

        nativeBuildInputs = prev.nativeBuildInputs ++ [ autoPatchelfHook ];
        # the native module links libgcc_s
        buildInputs = (prev.buildInputs or [ ]) ++ [ stdenv.cc.cc.lib ];

        postInstall = (prev.postInstall or "") + ''
            ${lib.concatStrings (
                lib.mapAttrsToList (name: tarball: ''
                    mkdir -p $out/lib/oxfmt/node_modules/@astrojs/${name}
                    tar xzf ${tarball} -C $out/lib/oxfmt/node_modules/@astrojs/${name} --strip-components=1
                '') astro
            )}
        '';
    }
)
