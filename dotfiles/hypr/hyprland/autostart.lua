local vars = require("hyprland.vars")

hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia")

	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("wl-clip-persist --clipboard regular")

	if vars.hostname == "kash-desktop" then
		hl.exec_cmd("v4l2-ctl -d /dev/video0 --set-ctrl=focus_automatic_continuous=0")
	end

	hl.exec_cmd("hyprctl reload")
end)
