{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.nixos.common =
        { pkgs, ... }:
        let
            editor = pkgs.${vars.apps.editor};
        in
        {

            environment.systemPackages = [
                editor
                pkgs.git
                pkgs.wget
            ];

            environment.variables = {
                EDITOR = editor.meta.mainProgram;
                VISUAL = editor.meta.mainProgram;
            };
        };
}
