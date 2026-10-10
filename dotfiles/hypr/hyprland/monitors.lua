local monitors = {
	left = "desc:HP Inc. HP S270n",
	right = "desc:HP Inc. OMEN by HP 27",
	main = "desc:AOC Q27G4ZR XZ1S1HA010862",

	laptop = "eDP-1",
}

-- Left
hl.monitor({
	output = monitors.left,
	mode = "2560x1440@60.0",
	position = "auto-left",
	scale = "1.0",
	sdr_eotf = "srgb",
})

-- Main
hl.monitor({
	output = monitors.main,
	mode = "2560x1440@240.0",
	position = "auto",
	scale = "1.0",
	sdr_eotf = "srgb",
})

-- Right
hl.monitor({
	output = monitors.right,
	mode = "2560x1440@144.0",
	position = "auto-right",
	scale = "1.0",
	sdr_eotf = "srgb",
})

-- -- Laptop
-- hl.monitor({
--  output = monitors.laptop,
--  mode = "1920x1200@60.0",
--  scale = "1.25",
-- })

hl.workspace_rule({ workspace = "1", monitor = monitors.left, default = true })
hl.workspace_rule({ workspace = "2", monitor = monitors.main, default = true })
hl.workspace_rule({ workspace = "3", monitor = monitors.right, default = true })

-- hl.workspace_rule({ workspace = "1", monitor = monitors.laptop })
