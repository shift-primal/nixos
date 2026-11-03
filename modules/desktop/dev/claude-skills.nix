{ config, ... }:

let
    inherit (config) vars;
in
{
    flake.modules.homeManager.desktop =
        { config, lib, ... }:
        let

            skills = lib.attrNames (
                lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../../dotfiles/claude/skills)
            );
            link = name: config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/claude/skills/${name}";
        in
        {
            home.file = lib.listToAttrs (
                map (name: lib.nameValuePair ".claude/skills/${name}" { source = link name; }) skills
            );
        };
}
