{
    pkgs,
    inputs,
    vars,
    ...
}:

let
    dotnet = pkgs.dotnetCorePackages.combinePackages (
        with pkgs.dotnetCorePackages;
        [
            sdk_8_0
            sdk_9_0
            sdk_10_0
        ]
    );

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

    templates = builtins.concatStringsSep " " (builtins.attrNames inputs.self.templates);
    project = pkgs.writeShellApplication {
        name = "project";
        text = ''
            templates="${templates}"
            usage() {
                echo "usage: project init --<template>" >&2
                echo "templates: $templates" >&2
                exit 1
            }

            [[ "''${1:-}" == init ]] || usage
            template="''${2:-}"
            template="''${template#--}"
            [[ -n "$template" && " $templates " == *" $template "* ]] || usage

            nix flake init -t "${vars.flakeDir}#$template"
            direnv allow
        '';
    };
in
{
    virtualisation.docker = {
        enable = true;
        daemon.settings.live-restore = true;
    };

    programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
    };

    users.users.${vars.user.name}.extraGroups = [
        "docker"
        "wireshark"
    ];

    environment.systemPackages = [
        dotnet
        pkgs.jetbrains.rider
        pythonWithSolaar
        project
    ];
    environment.sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";
}
