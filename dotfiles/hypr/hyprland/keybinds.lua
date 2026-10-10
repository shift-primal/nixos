local MOD = "SUPER"
local NOC = "noctalia msg"

local apps = {
	terminal = "kitty",
	editor = "nvim",
	sysmonitor = "btop",
	explorer = "yazi",
	browser = "firefox",
	discord = "vesktop",
	email = "betterbird",
	spotify = "spotify_player",
}

local function noctalia(cmd)
	return hl.dsp.exec_cmd(NOC .. " " .. cmd)
end

local function term(app)
	return hl.dsp.exec_cmd(apps.terminal .. " -e " .. app)
end

-- Noctalia Shell — Core
hl.bind(MOD .. " + SPACE", noctalia("panel-toggle launcher"), { description = "Noctalia launcher" })

hl.bind(MOD .. " + ESCAPE", noctalia("panel-toggle control-center"), { description = "Noctalia control center" })

hl.bind(MOD .. " + COMMA", noctalia("settings-toggle"), { description = "Noctalia settings panel" })

-- Media & Brightness
hl.bind(
	"XF86AudioRaiseVolume",
	noctalia("volume-up"),
	{ repeating = true, locked = true, description = "Raise volume" }
)

hl.bind(
	"XF86AudioLowerVolume",
	noctalia("volume-down"),
	{ repeating = true, locked = true, description = "Lower volume" }
)

hl.bind("XF86AudioMute", noctalia("volume-mute"), { locked = true, description = "Mute volume" })

hl.bind(MOD .. " + ALT + LEFT", noctalia("media previous"), { locked = true, description = "Previous song" })

hl.bind(MOD .. " + ALT + RIGHT", noctalia("media next"), { locked = true, description = "Next song" })

hl.bind(MOD .. " + ALT + SPACE", noctalia("media toggle"), { locked = true, description = "Play/pause song" })

hl.bind(
	"XF86MonBrightnessUp",
	noctalia("brightness-up"),
	{ repeating = true, locked = true, description = "Raise brightness" }
)

hl.bind(
	"XF86MonBrightnessDown",
	noctalia("brightness-down"),
	{ repeating = true, locked = true, description = "Lower brightness" }
)

-- Screenshot & recording

hl.bind(
	MOD .. " + SHIFT + S",
	noctalia("plugin alexander/screen-toolkit:service all toggle"),
	{ description = "Screen toolkit panel - Toggle" }
)

hl.bind(MOD .. " + S", noctalia("screenshot-region"), { description = "Screenshot region" })

hl.bind(
	MOD .. " + R",
	hl.dsp.exec_cmd(
		"bash -c '"
			.. 'if pgrep -f "gpu-screen-recorder -w [0-9]+x[0-9]+\\+[0-9]+\\+[0-9]+" >/dev/null; then '
			.. 'pkill -INT -f "gpu-screen-recorder -w [0-9]+x[0-9]+\\+[0-9]+\\+[0-9]+"; '
			.. "else "
			.. 'region=$(slurp -f "%wx%h+%x+%y"); '
			.. '[ -z "$region" ] && exit 0; '
			.. 'mkdir -p "$HOME/Videos/Recordings"; '
			.. 'out="$HOME/Videos/Recordings/recording_$(date +%Y%m%d_%H%M%S).mp4"; '
			.. 'gpu-screen-recorder -w "$region" -f 60 -k h264 -ac opus '
			.. '-a default_output -cursor yes -cr limited -o "$out" >/dev/null 2>&1 & disown; '
			.. "fi'"
	),
	{ description = "Record region (gpu-screen-recorder, no portal)" }
)

-- Session

hl.bind(MOD .. " + CONTROL + L", noctalia("session lock"), { description = "Lock computer" })

hl.bind("CTRL + ALT + DELETE", noctalia("panel-toggle session"), { description = "Power menu" })

-- Clipboard

hl.bind(MOD .. " + C", hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert" }), { description = "Universal copy" })

hl.bind(MOD .. " + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }), { description = "Universal paste" })

hl.bind(MOD .. " + X", hl.dsp.send_shortcut({ mods = "CTRL", key = "X" }), { description = "Universal cut" })

hl.bind(MOD .. " + Y", noctalia("panel-toggle clipboard"), { description = "Clipboard history" })

-- Tools

hl.bind(
	MOD .. " + B",
	noctalia("panel-toggle kenn/keybind-cheatsheet:cheatsheet"),
	{ description = "Keybind cheatsheet" }
)

hl.bind(
	MOD .. " + SHIFT + C",
	noctalia("plugin alexander/screen-toolkit:service all colorPicker"),
	{ description = "Color picker" }
)

hl.bind(
	MOD .. " + M",
	noctalia("plugin alexander/screen-toolkit:service all measure"),
	{ description = "Measure screen" }
)

-- App Launchers
hl.bind(MOD .. " + RETURN", hl.dsp.exec_cmd(apps.terminal), { description = "Terminal" })

hl.bind(MOD .. " + E", term(apps.explorer), { description = "File explorer" })

hl.bind(MOD .. " + SHIFT + N", term(apps.editor), { description = "Text editor" })

hl.bind(MOD .. " + SHIFT + B", hl.dsp.exec_cmd(apps.browser), { description = "Web browser" })

hl.bind(MOD .. " + SHIFT + D", hl.dsp.exec_cmd(apps.discord), { description = "Discord" })

hl.bind(MOD .. " + SHIFT + E", hl.dsp.exec_cmd(apps.email), { description = "Email" })

hl.bind(MOD .. " + SHIFT + M", term(apps.spotify), { description = "Spotify" })

-- Window Management
hl.bind(MOD .. " + W", hl.dsp.window.close(), { description = "Close focused window" })

hl.bind(MOD .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })

hl.bind(MOD .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })

local dirs = {
	{ key = "LEFT", vim = "H", dir = "l", label = "left" },
	{ key = "RIGHT", vim = "L", dir = "r", label = "right" },
	{ key = "UP", vim = "K", dir = "u", label = "up" },
	{ key = "DOWN", vim = "J", dir = "d", label = "down" },
}

for _, d in ipairs(dirs) do
	hl.bind(MOD .. " + " .. d.key, hl.dsp.focus({ direction = d.dir }), { description = "Focus " .. d.label })

	hl.bind(
		MOD .. " + " .. d.vim,
		hl.dsp.focus({ direction = d.dir }),
		{ description = "Focus " .. d.label .. " (vim)" }
	)

	hl.bind(
		MOD .. " + SHIFT + " .. d.key,
		hl.dsp.window.move({ direction = d.dir }),
		{ description = "Move window " .. d.label }
	)

	hl.bind(
		MOD .. " + SHIFT + " .. d.vim,
		hl.dsp.window.move({ direction = d.dir }),
		{ description = "Move window " .. d.label .. " (vim)" }
	)
end

hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Cycle focus forward" })

hl.bind("SHIFT + ALT + Tab", hl.dsp.window.cycle_next({ prev = true }), { description = "Cycle focus back" })

hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Hold to move window" })

hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Hold to resize window" })

-- Layout
hl.bind(MOD .. " + G", hl.dsp.layout("togglesplit"), { description = "Toggle split" })

hl.bind(MOD .. " + CTRL + G", hl.dsp.layout("swapsplit"), { description = "Swap split" })

-- Workspaces
for i = 1, 5 do
	hl.bind(MOD .. " + " .. i, hl.dsp.focus({ workspace = i }), { description = "Go to workspace " .. i })
	hl.bind(
		MOD .. " + SHIFT + " .. i,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move window to workspace " .. i }
	)
end
