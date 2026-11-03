{ config, ... }:

let
    inherit (config) vars;
    templates = builtins.concatStringsSep " " (builtins.attrNames config.flake.templates);
in
{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = [
                (pkgs.writeShellApplication {
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
                })
            ];
        };
}
