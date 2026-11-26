{
    flake.modules.nixos.nix-ld =
        { pkgs, ... }:
        {
            programs.nix-ld = {
                enable = true;
                libraries = with pkgs; [
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
                    systemd
                    libx11
                    libxcb
                    libxcomposite
                    libxdamage
                    libxext
                    libxfixes
                    libxrandr
                    icu
                    openssl
                    stdenv.cc.cc.lib
                    zlib
                ];
            };
        };
}
