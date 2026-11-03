_:

{
    flake.modules.nixos.desktop =
        { pkgs, ... }:
        {

            programs.nix-ld.enable = true;

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
                systemd
                libx11
                libxcb
                libxcomposite
                libxdamage
                libxext
                libxfixes
                libxrandr
            ];
        };
}
