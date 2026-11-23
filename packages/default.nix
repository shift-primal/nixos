{
    lib,
    pkgs,
    vars,
    ...
}:

let
    editor = pkgs.${vars.apps.editor};
in
{
    imports = [
        ./apps.nix
        ./ai.nix
        ./cli.nix
        ./wayland.nix
        ./gaming.nix
        ./nix.nix
    ];

    environment = {
        variables = {
            EDITOR = editor.meta.mainProgram;
            VISUAL = editor.meta.mainProgram;
        };
        systemPackages = map (name: pkgs.${name}) (lib.attrValues vars.apps);
    };
}
