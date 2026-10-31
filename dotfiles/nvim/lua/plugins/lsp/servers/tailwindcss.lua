return {
	mason = false,

	settings = {
		tailwindCSS = {
			files = {
				-- Tailwind's defaults, plus .direnv: nix-direnv keeps the flake's inputs
				-- (all of nixpkgs) there, and the server would crawl them for configs.
				exclude = {
					"**/.git/**",
					"**/node_modules/**",
					"**/.hg/**",
					"**/.svn/**",
					"**/.direnv/**",
				},
			},
		},
	},
}
