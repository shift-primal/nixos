_:

{
    # Chrome on this NVIDIA card reports HEVC as playable, but its frames (10-bit in most HEVC
    # releases) reach Hyprland as a black picture while the audio plays. With HEVC turned off, Chrome
    # no longer offers it, so Jellyfin web transcodes those streams to H.264 on the homelab
    # (modules/hosts/kash-homelab/intel.nix) instead of sending them as they are. The laptop's Intel
    # GPU decodes HEVC fine, so this stays on this machine. Only for Chrome (vars.apps.browser).
    flake.modules.nixos.kash-desktop = {
        nixpkgs.overlays = [
            (_: prev: {
                google-chrome = prev.google-chrome.override {
                    commandLineArgs = "--disable-features=PlatformHEVCDecoderSupport";
                };
            })
        ];
    };
}
