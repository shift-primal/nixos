# Layout Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize `modules/` into `common` / `desktop` / `homelab` roles with use-case subfolders, slim what every host gets, and move language toolchains into per-project flake templates.

**Architecture:** Stays dendritic: every file under `modules/` is a flake-parts module loaded by import-tree, adding to `flake.modules.<class>.<aspect>`. Folder layout does not affect evaluation, so the reorg is proven by comparing host derivations before and after. Templates are plain flakes under `templates/`, exposed through `flake.templates`.

**Tech Stack:** Nix flakes, flake-parts, import-tree, Home Manager (NixOS module), direnv + nix-direnv.

**Spec:** `docs/superpowers/specs/2026-10-30-layout-rework-design.md` (the file-move lists live there; this plan does not repeat them).

## Global Constraints

- Aspects after the rework: `common`, `desktop`, `homelab`, one per host. No `base`, `workstation`, `dev`, or per-service server aspects remain.
- Follow `CLAUDE.md` style: 4-space indent, `nixfmt`, file header lists only used args (`_:` when none), comments say why.
- `dotfiles/`, `pkgs/`, `secrets/` and the values in `modules/flake/vars.nix` do not change (comments mentioning old paths may be updated).
- `git add` every new or moved file before evaluating: the flake only sees tracked files.
- Work on branch `claude/task-ctmyt9`; one commit per task; push after each task. No PR.
- Commit messages end with the attribution lines from the session's system reminder.

## Verification setup (used by every task)

The container's proxy blocks Nix's GitHub tarball downloads, so evaluation uses a copy of `flake.lock` with GitHub nodes rewritten to shallow git fetches. This lives in the scratchpad and is never committed.

```bash
S=/tmp/claude-0/-home-user-nixos/9618a2c4-960c-5d12-944c-4876cb7c0e82/scratchpad
# $S/bin/gitlock.py already exists: rewrites "locked" github nodes to {type=git, url, rev, shallow=true}.
python3 -I $S/bin/gitlock.py flake.lock $S/git.lock
EV="nix eval --no-write-lock-file --reference-lock-file $S/git.lock"
drv()  { $EV --raw .#nixosConfigurations.$1.config.system.build.toplevel.drvPath; }
hmpk() { $EV --json .#nixosConfigurations.$1.config.home-manager.users.kasper.home.packages \
           --apply 'ps: builtins.sort builtins.lessThan (map (p: p.pname or p.name) ps)'; }
```

Each host evaluation takes about a minute.

## Review Focus

1. **List-order drift.** Moving files changes import-tree order, which can reorder `home.packages` or `environment.systemPackages` and change a drvPath with no real change. Expected: if Task 1's drvPaths differ, `nix-diff` must show only reordered list entries; any other difference is a bug. (Task 1, Step 5.)
2. **Double-imported Home Manager module.** Folding `dev` into `desktop` while leaving both `workstation/home.nix` and `dev/home.nix` would import `homeManager.desktop` twice. Expected: only `desktop/home.nix` exists. (Task 1, Step 3.)
3. **Relative paths after a move.** `builtins.readDir ../../dotfiles/claude/skills` gains a level under `desktop/dev/`. Expected: evaluation succeeds and the skills still link. (Task 1, Steps 3 and 5.)
4. **Template with an unlocked input.** A template flake has no lock; `nix flake init` + `direnv allow` must work on a fresh project. Expected: every template evaluates with only `nixpkgs` (and for `node`, this repo plus `nix-vite-plus`) as inputs. (Task 3, Step 6.)
5. **Homelab losing a tool it runs.** Expected: the homelab package list loses exactly the moved set from the spec, nothing else. (Task 2, Step 4.)

---

### Task 1: Move files into roles and rename aspects

**Files:**
- Move: every file under `modules/base/`, `modules/secrets/`, `modules/workstation/`, `modules/dev/`, `modules/server/` per the spec's "File moves" section.
- Delete: `modules/dev/home.nix`
- Modify: `modules/hosts/*/default.nix` (import lists), every moved file (aspect name), comments naming old paths in `modules/`, `pkgs/`, `dotfiles/`.

**Interfaces:**
- Produces: aspects `flake.modules.nixos.{common,desktop,homelab}` and `flake.modules.homeManager.{common,desktop}`. Hosts import `nixos.common` plus `nixos.desktop` or `nixos.homelab`.

- [ ] **Step 1: Record baselines** on the untouched tree: `drv` for kash-desktop, kash-laptop, kash-homelab into `$S/base-<host>.drv`; `hmpk` for all three into `$S/base-<host>.pkgs.json`.

- [ ] **Step 2: Move the files** with `git mv` to the spec's paths (`modules/common/{nix,system,network,shell}/`, `modules/common/secrets.nix`, `modules/desktop/{session,hardware,apps,theming,dev}/`, `modules/desktop/home.nix`, `modules/homelab/{edge,apps,media,ops}/`), all except `modules/dev/home.nix`. `komodo/`, `pocket-id/`, `media/` and `monitoring/` move as whole folders so their `_` files come along. Remove the now-empty old folders.

- [ ] **Step 3: Rename aspects and fix paths.**
  - `nixos.base`/`homeManager.base` → `common`; `nixos.workstation`/`homeManager.workstation` and `nixos.dev`/`homeManager.dev` → `desktop`; `nixos.{komodo,caddy,cloudflared,backup,monitoring,media,immich,pocket-id,opencloud,github-runners}` → `homelab`. This covers `flake.modules.*` definitions, `hm.base` in `common/home-manager.nix`, and `config.flake.modules.homeManager.workstation` in `desktop/home.nix`.
  - `git rm modules/dev/home.nix` (Step 2 leaves it in place; `desktop/home.nix` now covers it).
  - Host import lists: desktop/laptop → `nixos.common nixos.desktop`; homelab → `nixos.common nixos.homelab`.
  - `desktop/dev/claude-skills.nix`: `../../dotfiles` → `../../../dotfiles`. `common/secrets.nix` keeps `../../secrets` (same depth).
  - Update comments that name old paths or aspects: `grep -rnE "modules/(base|workstation|dev|server|secrets)|\b(base|workstation|server)/" modules pkgs dotfiles`.

- [ ] **Step 4: Check no old name is left.**
  Run: `grep -rnE "modules\.(nixos|homeManager)\.(base|workstation|dev|komodo|caddy|cloudflared|backup|monitoring|media|immich|pocket-id|opencloud|github-runners)\b|nixos\.(base|workstation|dev)\b" modules`
  Expected: no output. Then `nixfmt --check $(git ls-files 'modules/*.nix')` passes.

- [ ] **Step 5: Compare against baseline.** `git add -A`, regenerate nothing (lock unchanged), run `drv` for all three hosts.
  Expected: each equals `$S/base-<host>.drv`. If one differs, run `nix-diff <old.drv> <new.drv>` (via `nix run nixpkgs#nix-diff` with the git lock, or `nix shell`): accept only reordered list entries, also confirm `hmpk` matches the baseline JSON; anything else is fixed before continuing.

- [ ] **Step 6: Commit and push.** Message: `Reorganize modules into common, desktop and homelab roles`.

### Task 2: Slim `common`

**Files:**
- Modify: `modules/common/cli.nix`
- Create: `modules/desktop/dev/cli.nix`

**Interfaces:**
- Consumes: aspects from Task 1.
- Produces: `homeManager.desktop` holds the desktop-only CLI set listed in the spec's "Slim common" section.

- [ ] **Step 1: Split the list.** `common/cli.nix` keeps exactly the spec's common set; `desktop/dev/cli.nix` (`{ inputs, ... }:` header, adding to `flake.modules.homeManager.desktop`) gets the rest, keeping the existing comments (cloudflared/cutover note) with the packages they describe. The `inputs` header moves with the claude-code/antigravity entries; `common/cli.nix` becomes `_:` if it no longer uses `inputs`.

- [ ] **Step 2: `git add` and nixfmt.**

- [ ] **Step 3: Desktops unchanged.** `drv kash-desktop`, `drv kash-laptop`.
  Expected: equal to the Task 1 result (same packages, same aspect). Same `nix-diff` rule as Task 1 Step 5 if not.

- [ ] **Step 4: Homelab lost exactly the moved set.** `hmpk kash-homelab` and diff against `$S/base-kash-homelab.pkgs.json`.
  Expected: removed names are exactly rbw, bitwarden-cli, bws, obsidian-headless, lazysql, libnotify, yt-dlp, ffmpeg, ddcutil, evtest, gocryptfs, git-filter-repo, gowall, railway, cloudflared, cutover, stripe-cli, grok-cli, skills, claude-code, and the three antigravity packages (by their pname); nothing added.

- [ ] **Step 5: Commit and push.** Message: `Keep desktop-only CLI tools off the homelab`.

### Task 3: Per-project dev templates

**Files:**
- Create: `templates/{node,python,rust,go,c,dotnet}/{flake.nix,.envrc,.gitignore}`, `modules/flake/templates.nix`, `modules/flake/packages.nix`
- Delete: `modules/desktop/dev/{c,rust,go,dotnet}.nix`
- Modify: `modules/desktop/dev/web.nix`, `modules/desktop/dev/python.nix`, `modules/common/shell/tools.nix`

**Interfaces:**
- Produces: `flake.templates.<name> = { path; description; }` for the six names; `packages.x86_64-linux.<name>` for every attribute of `pkgs/default.nix`.

- [ ] **Step 1: Record the desktop package list** before changes: `hmpk kash-desktop > $S/t3-before.json`.

- [ ] **Step 2: Templates.** Each `flake.nix`: input `nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"`; output `devShells.x86_64-linux.default = pkgs.mkShell { packages = [ ... ]; }` with the spec's template table contents. `node` adds inputs `nixos.url = "github:shift-primal/nixos"` (with `inputs.nixpkgs.follows = "nixpkgs"`) for `oxfmt`, and `nix-vite-plus` (same URL and follows as the main `flake.nix`) for `vp`; `js-debug-adapter` is the same `writeShellScriptBin` wrapper as in today's `web.nix`. `dotnet` uses the same `combinePackages` of SDK 8/9/10. `.envrc`: `use flake`. `.gitignore`: `.direnv/`.

- [ ] **Step 3: Expose them.**
  - `modules/flake/templates.nix`: `flake.templates` with one entry per template, `path = ../../templates/<name>`, one-line `description`.
  - `modules/flake/packages.nix`: `perSystem` building `pkgs` from `inputs.nixpkgs` with `self.overlays.default` (`config.allowUnfree = true`) and setting `packages = lib.getAttrs (builtins.attrNames (import ../../pkgs { } { })) pkgs`.

- [ ] **Step 4: Trim global dev.** Delete `c.nix`, `rust.nix`, `go.nix`, `dotnet.nix`. `web.nix` keeps only the `oxc` link, `.oxfmtrc.json` link and npm session variable (drop `home.packages`, and header args it no longer uses). `python.nix` keeps `pythonWithSolaar`, drops pyright, ruff, black, pipx. `common/shell/tools.nix`: `direnv = { enable = true; nix-direnv.enable = true; };`. `git add -A`, nixfmt.

- [ ] **Step 5: Flake-level checks.**
  Run: `nix flake show --no-write-lock-file --reference-lock-file $S/git.lock`
  Expected: lists `templates.{c,dotnet,go,node,python,rust}` and `packages.x86_64-linux.{bagnard,circular-std,cutover,grok-cli,jellyfin-plugin-file-transformation,jellyfin-plugin-gelato,jellyfin-plugin-sleekfin,oxfmt}`.
  Run: `nix flake check --no-build --no-write-lock-file --reference-lock-file $S/git.lock`
  Expected: exit 0.

- [ ] **Step 6: Templates work.** For each template: `nix flake init -t /home/user/nixos#<name>` into a fresh dir under `$S/tpl/<name>`, then evaluate `devShells.x86_64-linux.default.drvPath` with `--override-input nixpkgs "git+https://github.com/nixos/nixpkgs?rev=<rev from flake.lock>&shallow=1"` (node also `--override-input nixos path:/home/user/nixos` and nix-vite-plus as git). Expected: all six evaluate. For `python`, `go`, `c`: `nix develop <same overrides> -c sh -c 'which python3 uv pyright ruff'` (resp. `go gopls`, `gcc clangd`). Expected: every tool found. The `.envrc` and `.gitignore` are present in each init'd dir.

- [ ] **Step 7: Desktop delta.** `hmpk kash-desktop` vs `$S/t3-before.json`.
  Expected removed: gcc, clang, rustc, cargo, rustfmt, clippy, the dotnet combined SDK, omnisharp-roslyn, fsautocomplete, csharpier, fantomas, netcoredbg, go, nodejs, pnpm, sassc, node-gyp, gnumake, oxfmt, oxlint, biome, typescript, astro-language-server, tailwindcss-language-server, vp, vscode-js-debug, js-debug-adapter, pyright, ruff, black, pipx. Nothing added. And `$EV .#nixosConfigurations.kash-desktop.config.home-manager.users.kasper.programs.direnv.nix-direnv.enable` → `true`. `drv kash-homelab` evaluates (nix-direnv is in `common`, so homelab changes too; that is expected).

- [ ] **Step 8: Commit and push.** Message: `Move language toolchains into per-project flake templates`.

### Task 4: Docs

**Files:**
- Modify: `CLAUDE.md`, `README.md`

- [ ] **Step 1: CLAUDE.md.** Intro and rule 1 name the aspects `common`, `desktop`, `homelab`; Layout block matches the new tree including `templates/`; "Where things go" points to the new paths (GUI app → `desktop/apps/apps.nix`, CLI tool → `common/cli.nix` or `desktop/dev/cli.nix` for desktop-only, new language → a template in `templates/<lang>/` plus its entry in `modules/flake/templates.nix`, global editor tooling → `desktop/dev/<lang>.nix`, homelab service → a file in the matching `homelab/` subfolder). Rule 6 says LSPs for project languages come from the project's devShell.

- [ ] **Step 2: README.md.** Host/aspect tables, Layout block, "Adding things", and a short "Dev environments" section: `nix flake init -t ~/nixos#<name>`, `direnv allow`, loads on `cd`, start nvim inside the project. Fix the stale line saying Komodo and Caddy are left out of the homelab.

- [ ] **Step 3: No stale references.**
  Run: `grep -nE "\b(base|workstation)\b|modules/(dev|server|secrets)/" CLAUDE.md README.md`
  Expected: no hits that refer to the old layout.

- [ ] **Step 4: Commit and push.** Message: `Document the new layout and dev templates`.
