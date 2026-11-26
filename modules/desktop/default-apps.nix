{
    flake.modules.nixos.default-apps =
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
            environment = {
                systemPackages = [ editor ];
                variables = {
                    EDITOR = editor.meta.mainProgram;
                    VISUAL = editor.meta.mainProgram;
                };
            };

            hm.home.packages = map (name: pkgs.${name}) (lib.attrValues (removeAttrs vars.apps [ "editor" ]));
        };
}
