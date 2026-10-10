{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  makeWrapper,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grok";
  version = "1.0.50";

  src = fetchurl {
    url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-x86_64";
    hash = "sha256-yA3gFVcG/y2ZViOIexAvLQq9LGKyZD3qOgzrr33XJNU=";
  };

  dontUnpack = true;

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/libexec/grok

    # The store path cannot be overwritten by `grok update`.
    makeWrapper $out/libexec/grok $out/bin/grok \
      --argv0 grok \
      --set GROK_DISABLE_AUTOUPDATER 1
    makeWrapper $out/libexec/grok $out/bin/agent \
      --argv0 agent \
      --set GROK_DISABLE_AUTOUPDATER 1

    installShellCompletion --cmd grok --zsh <($out/libexec/grok completions zsh)

    runHook postInstall
  '';

  meta = {
    description = "xAI Grok CLI";
    homepage = "https://x.ai";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "grok";
    platforms = [ "x86_64-linux" ];
  };
})
