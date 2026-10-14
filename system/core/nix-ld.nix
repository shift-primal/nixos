{ pkgs, ... }:

{
    # Lets prebuilt generic-Linux binaries (npm packages like @biomejs/cli-linux-x64) run without
    # patching; they look for a loader at /lib64/ld-linux-x86-64.so.2, which NixOS lacks.
    programs.nix-ld.enable = true;

    # Shared libraries those binaries expect in /usr/lib. This set covers the browsers Playwright
    # downloads to ~/.cache/ms-playwright (Chromium, headless shell, ffmpeg).
    programs.nix-ld.libraries = with pkgs; [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        glib
        libdrm
        libgbm
        libxkbcommon
        nspr
        nss
        pango
        systemd # libudev
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
    ];
}
