{ config, ... }:

let
    inherit (config) vars;
    # The templates in modules/flake/templates.nix, so a new one is accepted without editing this file.
    templates = builtins.concatStringsSep " " (builtins.attrNames config.flake.templates);
in
{
    # `project init --node`: copies the dev shell template into the current directory and allows
    # its .envrc, so the env loads right away. nix and direnv come from PATH (common/shell/tools.nix).
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
