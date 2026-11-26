# NixOS config

Flake for `kash-desktop` and `kash-laptop`, with Home Manager as a NixOS module. Dendritic
layout: flake-parts + import-tree, every file under `modules/` is loaded automatically and
defines named pieces that hosts pick. `/etc/nixos` links here (`modules/system/nix.nix`). Apply
with `sudo nixos-rebuild switch`.

The home server is a separate repo, `shift-primal/homelab` (`~/homelab`). Nothing here builds it.

The user is not a Nix expert and wants the config kept simple. Prefer the plainest NixOS idiom
that works; do not add abstractions, options or helper layers beyond the ones below.

## How it fits together

- `flake.nix` only lists inputs; outputs are `mkFlake … (import-tree ./modules)`.
- Every `.nix` file under `modules/` is a **flake-parts module** (outer level). It defines one
  **piece**, a normal NixOS module (inner level), by name:
  ```nix
  {
      flake.modules.nixos.git =
          { pkgs, ... }:
          {
              environment.systemPackages = [ pkgs.git ];
              hm.programs.git.enable = true;
          };
  }
  ```
  Defining a piece does not turn it on. A piece's name is its attribute, not its path; names
  must be unique across the repo (two files defining the same name silently merge).
- `modules/bundles.nix` groups pieces into bundles named after their folders: `system`,
  `hardware`, `desktop`, `shell`, `dev`, `apps`. A bundle lists every piece in its folder
  except host-only ones (`nvidia`, `intel-graphics`, `autologin`).
- `modules/hosts/<host>/default.nix` calls `nixosSystem` with the bundles plus host-only pieces,
  `./_hardware-configuration.nix` and `./_machine.nix` (hostName, stateVersion, bootloader,
  machine-only bits).
- `modules/flake/parts.nix` provides the outer-level args `aspects` (the pieces, each wrapped
  with a `key` so listing one twice loads it once) and `vars` (`import ../../vars.nix`).
- Inner modules get `inputs` and `vars` through `specialArgs`, so headers look like
  `{ pkgs, vars, ... }:`. Outer files get `aspects`, `inputs`, `vars`, `config` (the flake's,
  not the system's), `lib`.
- `modules/system/users.nix` (in the `system` bundle, so on every host) adds two helpers:
  - `hm` is an alias for `home-manager.users.${vars.user.name}`. Use it for all Home Manager
    config: `hm.home.packages = …`, or `hm = { config, lib, ... }: { … };` when HM's own
    `config`/`lib` is needed.
  - `link "<path under dotfiles/>"` makes a live `mkOutOfStoreSymlink` into the repo. Take it as
    a module arg: `{ link, ... }:`.

## Layout

```
flake.nix        inputs; outputs = import-tree ./modules
vars.nix         plain attrset: user, flakeDir, hosts (ssh aliases), locale, keyboard, cursor, apps
pkgs/            overlay (pkgs/default.nix): nixfmt-wrapped
dotfiles/        live-edited configs: hypr, kitty, nvim, zsh, starship, noctalia, oxc, tombi,
                 stylua, ruff, btop, ideavim, claude
modules/
  flake/         parts.nix (flake-parts setup, aspects, vars), packages.nix (overlay, formatter)
  bundles.nix
  hosts/<host>/  default.nix, _hardware-configuration.nix, _machine.nix
  system/        nix (settings, gc, overlays, /etc/nixos link, rebuild), boot, locale, users,
                 network, ssh
  hardware/      audio (+ easyeffects), printing, peripherals (bluetooth, solaar, i2c/ddcutil,
                 fwupd), nvidia, intel-graphics
  desktop/       hyprland (+ vars.lua), wayland-tools, noctalia, keyring, autologin, theme,
                 fonts, session, splash, kitty, luciole, default-apps
  shell/         zsh, git, plugins (direnv, zoxide, starship, fzf), cli-tools
  dev/           docker, wireshark, jetbrains, dotnet, web, languages, cloud, config-tools,
                 neovim, nix-ld
  apps/          ai, bitwarden, general (media, office, filezilla, artcraft), gaming
```

## Where things go

- **A feature keeps everything in its own file:** its NixOS options, its Home Manager config
  (`hm.…`), its packages, its dotfile links and its zsh variables.
- **Packages:** in the file of the feature that uses them. User tools go in
  `hm.home.packages` (or `hm.programs.<x>`). Use `environment.systemPackages` only when the
  package needs the system (has a NixOS module, groups, udev, setcap, fonts, hardware) or is run
  with sudo or in a rescue shell (git, curl, wget, the editor). An env var GUI apps need goes in
  `environment.sessionVariables`; one only shells need goes in `hm.programs.zsh.sessionVariables`.
- Only use `hm.programs.<x>` when Home Manager should own that program's config. Otherwise
  install the package and link its config from `dotfiles/` (for example `gh`: a plain package,
  so `gh config set` still works).
- **New feature:** a new file in the matching folder defining `flake.modules.nixos.<name>`, then
  add `<name>` to that folder's bundle in `modules/bundles.nix`. `git add` it.
- A default app bound to a key goes in `vars.apps` (nixpkgs attribute name);
  `desktop/default-apps.nix` installs it and the keybinds read it through `vars.lua`.
- Editor-only language server: Mason, installed through Lazy. Add it to `servers` in
  `dotfiles/nvim/lua/plugins/lsp/lsp.lua`; a server provided by Nix is marked
  `mason = false` there. Mason's `ensure_installed` stays empty
  (`dotfiles/nvim/lua/plugins/lsp/mason.lua`) so it does not duplicate Nix tools.
- Other global dev tool for a language (runtime, formatter, linter, anything also run in a
  terminal): the matching file in `modules/dev/`. Tools for editing this config:
  `dev/config-tools.nix`. No mise.
- A project's JS tools (typescript, oxlint, oxfmt, vite): that project's `package.json`.
- Per-project pinned tools: a `flake.nix` dev shell in that project, entered by direnv
  `use flake`. `dev init <name>` (`dotfiles/zsh/rc.zsh`) copies it from
  `the-nix-way/dev-templates`.
- Only one machine: a host-only piece (GPU, autologin) named in that host's `default.nix`, or
  that host's `_machine.nix` (bootloader, monitors-related, one-offs like reboot-to).
- New dotfile: put it in `dotfiles/` and link it with `link` in the file of the feature that owns
  it.
- zsh: Home Manager owns `~/.config/zsh/.zshrc` (`shell/zsh.nix`); it ends by sourcing
  `dotfiles/zsh/rc.zsh`, where aliases and functions live (live-edited).
- Hyprland setting for one machine: `dotfiles/hypr/hyprland/hosts/<hostname>.lua`. It loads last
  from `hyprland.lua`, so set only the keys that differ.
- Package not in nixpkgs: `pkgs/<name>.nix`, registered in `pkgs/default.nix`.
- New overlay: `nixpkgs.overlays` in `system/nix.nix`, so every piece sees the same `pkgs`.
- New machine: copy a folder in `modules/hosts/`, change the hostname in its `default.nix`
  (`flake.nixosConfigurations.<hostname>`) and `_machine.nix`, add it to `vars.hosts`, save its
  generated hardware config as `_hardware-configuration.nix`. First switch:
  `sudo nixos-rebuild switch --flake ~/nixos#<hostname>` after moving the installer's
  `/etc/nixos` away.

## Rules

1. **One source of truth.** A value used in more than one place lives in `vars.nix` and is read
   from there. Never hard-code `kasper`, `/home/kasper`, the hostname or `~/nixos`; use
   `vars.user.name`, `vars.user.home`, `config.networking.hostName`, `vars.flakeDir`.
2. **Dotfiles stay live-editable.** Program configs live in `dotfiles/` and are linked with
   `link`. Edits apply without a rebuild. Do not convert them to Home Manager
   `programs.<x>.settings`.
3. **Dotfiles read Nix values from `~/.config/nixos-vars/vars.lua`**, generated in
   `desktop/hyprland.nix` from `vars.nix`. Hyprland loads it through
   `dotfiles/hypr/hyprland/vars.lua`. To share a new value, add it to `vars.nix` and to `luaVars`
   in `desktop/hyprland.nix`.
4. **No plaintext secrets in the repo; it is public.** Never commit passwords, API keys, tokens,
   private keys, Wi-Fi passphrases or anything else that grants access, including in `dotfiles/`
   and in Nix strings (they end up in the world-readable `/nix/store`). Use Bitwarden via `bws`
   at runtime. Before committing, check the diff for anything secret-looking, and stop and ask
   if unsure.
5. **Noctalia drives every app's colors.** The scheme is picked in `dotfiles/noctalia/config.toml`
   (`[theme]`, currently built-in `Gruvbox`) and its templates (`[theme.templates]`) write
   the colors into Hyprland, kitty, btop, GTK, Qt (qt5ct/qt6ct, `desktop/theme.nix`), Discord,
   Steam, Claude Code, fzf, lazygit and the Gruvbox Plus folder icons. Do not set
   colors directly in an app's config. Noctalia adds and removes its own include lines
   (`require("noctalia")` in `hyprland.lua`, `include themes/noctalia.conf` in `kitty.conf`,
   `color_theme` in `btop.conf`); leave them. The exception is Neovim: it uses
   `ellisonleao/gruvbox.nvim` (`lua/plugins/ui/colorscheme.lua`) for full Treesitter and plugin
   highlights, so change it by hand if the Noctalia scheme changes.

## Style

- No comments by default. A comment stays only where a line would otherwise look wrong and
  someone would "fix" it, such as a workaround.
- File header: only the args used (`{ pkgs, vars, ... }:`).
- `with pkgs; [ ... ]` for package lists. Inside `with pkgs`, a `let` name wins over a package
  of the same name, so do not name a `let` binding after a package.
- Format with `nix fmt`.

## Working here

- The flake only sees files git tracks. `git add` new files before building; an untracked piece
  shows up as "attribute '<name>' missing".
- A plain NixOS file under `modules/` (not a flake-parts module) must start with `_`, or
  import-tree loads it as a flake-parts module and fails with an unknown-option error.
- Verify with `nix build --no-link .#nixosConfigurations.<hostname>.config.system.build.toplevel`
  for both hosts, and compare with `nix store diff-closures /run/current-system <result>`. Do
  not build scratch test projects to check config changes.
- Edits under `dotfiles/` go live immediately. Hyprland hot-reloads, so a Lua edit that needs a
  new `vars.lua` value breaks until the rebuild. Tell the user to rebuild before testing.
- Tell the user to apply with plain `sudo nixos-rebuild switch`.
- Do not commit unless asked.
