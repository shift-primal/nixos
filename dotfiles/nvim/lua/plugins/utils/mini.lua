return {
	"nvim-mini/mini.hipatterns",
	version = false,
	opts = function()
		local hi = require("mini.hipatterns")

		local function oklch_gamma(c)
			c = math.min(math.max(c, 0), 1)
			if c <= 0.0031308 then
				return 12.92 * c
			end
			return 1.055 * c ^ (1 / 2.4) - 0.055
		end

		local function oklch_to_hex(l, c, h)
			local rad = math.rad(h)
			local a, b = c * math.cos(rad), c * math.sin(rad)

			local l_, m_, s_ =
				l + 0.3963377774 * a + 0.2158037573 * b,
				l - 0.1055613458 * a - 0.0638541728 * b,
				l - 0.0894841775 * a - 1.2914855480 * b
			local ll, mm, ss = l_ ^ 3, m_ ^ 3, s_ ^ 3

			local r = oklch_gamma(4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss)
			local g = oklch_gamma(-1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss)
			local bl = oklch_gamma(-0.0041960863 * ll - 0.7034186147 * mm + 1.7076147010 * ss)

			return string.format(
				"#%02x%02x%02x",
				math.floor(r * 255 + 0.5),
				math.floor(g * 255 + 0.5),
				math.floor(bl * 255 + 0.5)
			)
		end

		---@param token string
		---@param max_pct number value that a "100%" token maps to
		local function oklch_num(token, max_pct)
			if token == "none" then
				return 0
			end
			if token:sub(-1) == "%" then
				return (tonumber(token:sub(1, -2)) or 0) / 100 * max_pct
			end
			return tonumber(token)
		end

		local function parse_oklch(match)
			local body = match:match("^oklch%((.+)%)$")
			if not body then
				return nil
			end
			local tokens = {}
			for tok in body:gmatch("[^%s/]+") do
				table.insert(tokens, tok)
			end
			if #tokens < 3 then
				return nil
			end

			local l = oklch_num(tokens[1], 1)
			local c = oklch_num(tokens[2], 0.4)
			local h = oklch_num((tokens[3]:gsub("deg$", "")), 1)
			if not (l and c and h) then
				return nil
			end
			return l, c, h
		end

		return {
			tailwind = {
				enabled = true,
				ft = {
					"astro",
					"css",
					"heex",
					"html",
					"html-eex",
					"javascript",
					"javascriptreact",
					"rust",
					"svelte",
					"typescript",
					"typescriptreact",
					"vue",
				},
				style = "full",
			},
			highlighters = {
				hex_color = hi.gen_highlighter.hex_color({ priority = 2000 }),
				oklch_color = {
					pattern = "oklch%([^%)]+%)",
					group = function(_, _, data)
						local l, c, h = parse_oklch(data.full_match)
						if not l then
							return
						end
						return MiniHipatterns.compute_hex_color_group(oklch_to_hex(l, c, h), "bg")
					end,
					extmark_opts = { priority = 2000 },
				},
				shorthand = {
					pattern = "()#%x%x%x()%f[^%x%w]",
					group = function(_, _, data)
						---@type string
						local match = data.full_match
						if match == "#add" then
							return
						end
						local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
						local hex_color = "#" .. r .. r .. g .. g .. b .. b

						return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
					end,
					extmark_opts = { priority = 2000 },
				},
			},
		}
	end,
}
