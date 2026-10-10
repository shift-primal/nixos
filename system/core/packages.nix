{ pkgs, vars, ... }:

let
    editor = pkgs.${vars.apps.editor};
in
{
    # Still on PATH from a TTY if Home Manager fails to activate.
    environment.systemPackages = [
        editor
        pkgs.git
        pkgs.wget
    ];

    # Set for every session, so GUI apps and kitty inherit it too.
    environment.variables = {
        EDITOR = editor.meta.mainProgram;
        VISUAL = editor.meta.mainProgram;
    };
}
