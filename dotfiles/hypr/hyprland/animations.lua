-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("wind", { type = "bezier", points = { { 0.12, 0.92 }, { 0.08, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.18, 0.95 }, { 0.22, 1.03 } } })
hl.curve("linear", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "wind", style = "popin 60%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "overshot", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "overshot", style = "popin 60%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "overshot", style = "slide" })

hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "wind", style = "popin" })

hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "wind" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "wind" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "wind" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "wind" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "wind" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 4, bezier = "wind" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "overshot", style = "slidevert" })

hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "linear" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 1, bezier = "linear", loop = true })
