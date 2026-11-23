local opaque_classes = {
	"steam_app_.*",
	".*celluloid.*",
	".*mpv.*",
	".*vlc.*",
}

local function apply_opaque_rules()
	for _, class in ipairs(opaque_classes) do
		hl.window_rule({ match = { class = class }, opacity = 1 })
	end
end

local function merge(base, extra)
	local result = {}
	for k, v in pairs(base) do
		result[k] = v
	end
	for k, v in pairs(extra) do
		result[k] = v
	end
	return result
end

-- RuneLite menus and tooltips (win0, win1, ...)
hl.window_rule({
	match = { class = "^(net-runelite-client-RuneLite)$", title = "^(win[0-9]+)$" },
	no_initial_focus = true,
})

-- JetBrains welcome screen
hl.window_rule({ match = { class = "^(jetbrains-.*)$", title = "^(Welcome to JetBrains.*)$" }, float = true })

-- Picture in picture
hl.window_rule({
	match = { tag = "picture-in-picture" },
	float = true,
	keep_aspect_ratio = true,
	move = "73% 72%",
	size = { "monitor_w*0.25", "monitor_h*0.25" },
	pin = true,
})

-- No screenshare on Bitwarden
hl.window_rule({
	match = { class = "^(Bitwarden)$" },
	no_screen_share = true,
})

-- XWayland Popups
local xwayland_popup = { class = "^$", xwayland = true, float = true }

hl.window_rule({
	match = merge(xwayland_popup, { title = "^$", fullscreen = false, pin = false }),
	no_initial_focus = true,
})
hl.window_rule({
	match = xwayland_popup,
	no_blur = true,
})

-- Apply opaque rules
apply_opaque_rules()

-- Layers with no animation
for _, ns in ipairs({ "hyprpicker", "selection" }) do
	hl.layer_rule({ match = { namespace = ns }, no_anim = true })
end

-- Noctalia background
hl.layer_rule({
	match = { namespace = "^noctalia-background-" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.5,
})
