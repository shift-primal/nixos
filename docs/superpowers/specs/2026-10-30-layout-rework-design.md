# Layout rework: hosts by role, features by use case

## Goal

Make the repo read as "which machine, then which use case", keep the dendritic
pattern (flake-parts + import-tree), stop desktop tools from landing on the homelab,
and move language toolchains out of the system into per-project dev environments.

Out of scope: replacing Home Manager (Hjem can be a later, separate change),
wrapper-modules, any change to `dotfiles/`, `pkgs/`, `secrets/` or `vars.nix` values.

## Aspects

| Aspect      | Replaces                                                                                                   | Imported by              |
| ----------- | ---------------------------------------------------------------------------------------------------------- | ------------------------ |
| `common`    | `base`                                                                                                     | all hosts                |
| `desktop`   | `workstation`, `dev`                                                                                       | kash-desktop, kash-laptop |
| `homelab`   | `komodo`, `caddy`, `cloudflared`, `backup`, `monitoring`, `media`, `immich`, `pocket-id`, `opencloud`, `github-runners` | kash-homelab             |
| `<hostname>` | unchanged                                                                                                 | its host                 |

Each NixOS aspect keeps its Home Manager twin (`common/home-manager.nix`,
`desktop/home.nix`). `homelab` has no Home Manager side.

Host import lists become `common + desktop + hardware` and
`common + homelab + hardware`. Host-level settings (homelab domains, users, runners,
tunnel id) stay in `modules/hosts/kash-homelab/default.nix`.

## File moves

`common/` (was `base/`, plus `secrets/`):

- `nix/`: nix, gc, flake-link, rebuild
- `system/`: boot, locale, zram, fwupd, users, packages
- `network/`: networking, openssh, tailscale
- `shell/`: zsh, tools
- top level: cli, home-manager, dotfiles, `secrets.nix` (was `secrets/sops.nix`)

`desktop/` (was `workstation/` and `dev/`):

- `session/`: hyprland, greeter, portal, plymouth, noctalia, keyring, askpass, reboot-to
- `hardware/`: audio, easyeffects, bluetooth, printing, logitech, i2c
- `apps/`: apps, default-apps, media, steam, claude-desktop, clipboard, trash, entries, nix-ld
- `theming/`: theme, cursor, fonts, vars-lua, dotfiles
- `dev/`: neovim, nix, lua, shell, toml, markdown, docker, wireshark, claude-skills,
  web, python, and (until step 3) c, rust, go, dotnet
- `home.nix` (was `workstation/home.nix`; `dev/home.nix` is dropped)

`homelab/` (was `server/`):

- `edge/`: caddy, cloudflared, tailscale-https, local-names
- `apps/`: `komodo/`, immich, opencloud, `pocket-id/`
- `media/`: unchanged contents
- `ops/`: backup, `monitoring/`, github-runners

Relative paths that cross folders (e.g. `../../dotfiles/claude/skills` in
claude-skills.nix) are adjusted to the new depth. `_`-prefixed helper files move
with their folder.

## Slim `common`

`common/cli.nix` keeps tools useful on any host: ripgrep, fd, eza, jq, curl, openssl,
tree, dnsutils, unzip, zip, 7zz, lazygit, gh, sqlite, trash-cli, fastfetch.

New `desktop/dev/cli.nix` takes the rest: rbw, bitwarden-cli, bws, obsidian-headless,
lazysql, libnotify, yt-dlp, ffmpeg, ddcutil, evtest, gocryptfs, git-filter-repo,
gowall, railway, cloudflared, cutover, stripe-cli, grok-cli, skills, claude-code,
antigravity (all three packages).

`cutover` and `cloudflared tunnel route dns` are run from a desktop, so they leave
the homelab.

## Per-project dev environments

Stays global in `desktop/dev/` (needed for editing configs and scripts anywhere):
nil, nixfmt, statix, treefmt, lua-language-server, stylua, shfmt, tombi, marksman,
prettier, docker LSPs, hadolint, tree-sitter, `python3` with solaar and debugpy.
`web.nix` keeps only the `oxc` dotfile link, the `.oxfmtrc.json` link and the npm
session variable.

Removed from the system, provided by templates instead:

| Template | devShell                                                                                                   |
| -------- | ---------------------------------------------------------------------------------------------------------- |
| `node`   | nodejs, pnpm, typescript, biome, oxfmt, oxlint, astro/tailwind LSPs, vite-plus, js-debug-adapter, gnumake, node-gyp, sassc |
| `python` | python3, uv, pyright, ruff, debugpy                                                                        |
| `rust`   | rustc, cargo, rustfmt, clippy, rust-analyzer                                                               |
| `go`     | go, gopls                                                                                                  |
| `c`      | gcc, clang-tools                                                                                           |
| `dotnet` | SDK 8/9/10, omnisharp-roslyn, fsautocomplete, csharpier, fantomas, netcoredbg                              |

`c.nix`, `rust.nix`, `go.nix`, `dotnet.nix` are deleted. `python.nix` drops
pyright, ruff, black and pipx.

Wiring:

- `templates/<name>/flake.nix` (one `devShells.default`) and `templates/<name>/.envrc`
  (`use flake`).
- `modules/flake/templates.nix` exposes them as `flake.templates.<name>`.
- The flake exposes the overlay's packages as `packages.x86_64-linux` so the node
  template can take `github:shift-primal/nixos` as an input for `oxfmt`; it takes
  `nix-vite-plus` directly for `vp`.
- `programs.direnv.nix-direnv.enable = true` in `common/shell/tools.nix`: cached envs
  and a GC root per project.

Usage: `nix flake init -t ~/nixos#<name>`, `direnv allow`. The env loads on `cd` into
the project and unloads on leaving. Neovim sees the project tools when started from
inside the project.

## Steps and verification

Four commits on `claude/task-ctmyt9`, pushed at the end, no PR unless asked.

1. **Moves and aspect renames.** Check: `toplevel.drvPath` of all three hosts is
   identical before and after. Any difference is traced with `nix-diff` before going on.
2. **Slim `common`.** Check: both desktop drvPaths unchanged; the homelab's Home
   Manager package list loses exactly the moved packages.
3. **Templates, packages output, nix-direnv.** Check: `nix flake check`,
   `nix flake show` lists the templates, every template devShell evaluates; python,
   go and c shells are built and their tools found with `which` inside `nix develop`;
   the desktop package list loses exactly the moved toolchains and gains nix-direnv.
4. **Docs.** `CLAUDE.md` (layout, rules, where things go) and `README.md` updated to
   the new names and the templates workflow.

Not done in the container: full host builds and `switch`. After step 3 the user runs
`sudo rebuild switch` on each machine. Each step is its own commit, so any one can be
reverted.
