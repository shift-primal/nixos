_:

{
    # Chrome runs under XWayland on this machine. On native Wayland, 10-bit video (AV1 and HEVC
    # releases in Jellyfin web) plays with sound but a black picture on the NVIDIA card, and Hyprland
    # warns about 10-bit color; turning off hardware decode or Chrome's color-management protocol
    # doesn't help, XWayland does. Every monitor runs at scale 1 (dotfiles/hypr/hyprland/hosts/
    # kash-desktop.lua), so XWayland costs no sharpness. The laptop (Intel) stays on Wayland.
    # Only for Chrome (vars.apps.browser).
    flake.modules.nixos.kash-desktop = {
        nixpkgs.overlays = [
            (_: prev: {
                google-chrome = prev.google-chrome.override {
                    commandLineArgs = "--ozone-platform=x11";
                };
            })
        ];
    };
}
