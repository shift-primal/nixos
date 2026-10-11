{
    lib,
    pkgs,
    vars,
    ...
}:

# Exposes vars.nix to the live-edited Lua dotfiles as
# ~/.config/nixos-vars/vars.lua. Load it with:
#   dofile(os.getenv("HOME") .. "/.config/nixos-vars/vars.lua")
let
    luaVars = {
        inherit (vars) hostname keyboard;
        cursor = { inherit (vars.cursor) name size; };
        # Commands, not package names: { browser = "firefox", spotify = "spotatui", ... }
        apps = lib.mapAttrs (_: name: pkgs.${name}.meta.mainProgram) vars.apps;
    };
in
{
    xdg.configFile."nixos-vars/vars.lua".text = ''
        -- Generated from ~/nixos/vars.nix. Edit that file and rebuild.
        return ${lib.generators.toLua { } luaVars}
    '';
}
