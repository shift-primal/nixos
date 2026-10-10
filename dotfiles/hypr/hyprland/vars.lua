-- Values owned by ~/nixos/vars.nix (keyboard, cursor, default apps).
-- Home Manager generates the file below; edit vars.nix and rebuild to change them.
local path = os.getenv("HOME") .. "/.config/nixos-vars/vars.lua"

local ok, vars = pcall(dofile, path)
if not ok then
	error(path .. " is missing, run `sudo nixos-rebuild switch --flake ~/nixos` and reload Hyprland", 0)
end

return vars
