local cursor = require("hyprland.vars").cursor

hl.env("HYPRCURSOR_THEME", cursor.name)
hl.env("HYPRCURSOR_SIZE", tostring(cursor.size))
hl.env("XCURSOR_THEME", cursor.name)
hl.env("XCURSOR_SIZE", tostring(cursor.size))
