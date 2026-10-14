{ pkgs, ... }:

let
  # The Noctalia mx-control plugin runs the plain `python3` on PATH and imports Solaar's
  # libraries from it (system/hardware/logitech.nix). Solaar's own wrapper sets up the
  # GTK typelibs; repeat them here. Solaar bundles hid_parser, hence ignoreCollisions.
  typelibs = pkgs.lib.makeSearchPathOutput "out" "lib/girepository-1.0" (
    with pkgs;
    [
      glib
      gobject-introspection
      gtk3
      gdk-pixbuf
      pango
      harfbuzz
      at-spi2-core
    ]
  );
  python =
    (pkgs.python3.withPackages (ps: [
      ps.debugpy
      (ps.toPythonModule pkgs.solaar)
    ])).override
      { ignoreCollisions = true; };
  pythonWithSolaar = pkgs.symlinkJoin {
    name = "python3-solaar";
    paths = [ python ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/python3 --prefix GI_TYPELIB_PATH : ${typelibs}";
  };
in
{
  home.packages = with pkgs; [
    pythonWithSolaar
    pyright
    ruff
    black
    pipx
  ];
}
