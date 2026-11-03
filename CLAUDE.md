# NixOS config

Flake for `kash-desktop` and `kash-laptop`, with Home Manager as a NixOS module. Plain NixOS
modules: no flake-parts, no import-tree, no aspects. `/etc/nixos` links here
(`system.nix`). Apply with `sudo nixos-rebuild switch`.

The home server is a separate repo, `shift-primal/homelab` (`~/homelab`). Nothing here builds it.

The user is not a Nix expert and wants the config kept simple. Prefer the plainest NixOS idiom
that works; do not add abstractions, options or helper layers.

## Layout

```
flake.nix        inputs; nixosConfigurations (specialArgs = { inputs, vars }), formatter, overlay
vars.nix         plain attrset: user, flakeDir, hosts (ssh aliases), locale, keyboard, cursor, apps
packages.nix     environment.systemPackages: apps, CLI tools, config-editing tools
system.nix       nix settings, gc, /etc/nixos link, rebuild helper, boot, locale, users,
                 network, ssh, tailscale, zram, fwupd, nix-ld
desktop.nix      Hyprland, greeter, Noctalia, portal, keyring, plymouth, fonts, steam,
                 reboot-to, claude-desktop; HM: cursor, GTK/Qt theme, askpass, trash
hardware.nix     audio, bluetooth, i2c, solaar, printing; HM: easyeffects
dev.nix          docker, wireshark, Rider + .NET SDK and tools, mise shims on PATH
home.nix         Home Manager: zsh, git, direnv/zoxide/starship/fzf, every dotfile link,
                 vars.lua, claude skills, mise-install user service (runs after login)
hosts/<host>/    default.nix (imports, hostName, stateVersion, bootloader, GPU, machine-only
                 config), hardware-configuration.nix
pkgs/            overlay (pkgs/default.nix): nixfmt-wrapped, oxfmt with Astro support
dotfiles/        live-edited configs: hypr, kitty, nvim, zsh, starship, noctalia, oxc, mise, btop, claude
```

## Where things go

- App or CLI tool: `packages.nix`. A default app bound to a key goes in `vars.apps` instead
  (nixpkgs attribute name); the keybinds read it through `vars.lua`.
- Dev tool for a language (runtime, LSP, formatter, linter): `dotfiles/mise/config.toml`, not
  Nix. Mason stays disabled (`dotfiles/nvim/lua/plugins/lsp/mason.lua`); mise is the one place
  dev tools live. Nix keeps only tools for editing this config, oxfmt (`pkgs/oxfmt.nix`, needed
  for `.astro`), and the .NET SDK and tools for Rider (`dev.nix`), because a GUI IDE started
  from the launcher does not see the shell PATH.
- System service or hardware: the topical file (`desktop.nix`, `hardware.nix`, `dev.nix`,
  `system.nix`). Home Manager config for that feature goes in the same file under
  `home-manager.users.${vars.user.name}`, so a feature stays in one place.
- Only one machine (monitors, GPU, bootloader): `hosts/<host>/default.nix`.
- New dotfile: put it in `dotfiles/` and add a line to the `xdg.configFile` link list in
  `home.nix`.
- Hyprland setting for one machine: `dotfiles/hypr/hyprland/hosts/<hostname>.lua`. It loads last
  from `hyprland.lua`, so set only the keys that differ.
- Package not in nixpkgs: `pkgs/<name>.nix`, registered in `pkgs/default.nix`.
- New machine: copy a folder in `hosts/`, add the hostname to the list in `flake.nix` and to
  `vars.hosts`, save its generated `hardware-configuration.nix` there. First switch:
  `sudo nixos-rebuild switch --flake ~/nixos#<hostname>` after moving the installer's
  `/etc/nixos` away.

## Rules

1. **One source of truth.** A value used in more than one place lives in `vars.nix` and is read
   from there. Modules get it as an argument: `{ pkgs, vars, ... }:`. Never hard-code `kasper`,
   `/home/kasper`, the hostname or `~/nixos`; use `vars.user.name`, `vars.user.home`,
   `config.networking.hostName`, `vars.flakeDir`.
2. **Dotfiles stay live-editable.** Program configs live in `dotfiles/` and are linked with
   `mkOutOfStoreSymlink` (the `link` helper in `home.nix`). Edits apply without a rebuild. Do not
   convert them to Home Manager `programs.<x>.settings`.
3. **Dotfiles read Nix values from `~/.config/nixos-vars/vars.lua`**, generated in `home.nix`
   from `vars.nix`. Hyprland loads it through `dotfiles/hypr/hyprland/vars.lua`. To share a new
   value, add it to `vars.nix` and to `luaVars` in `home.nix`.
4. **No plaintext secrets in the repo; it is public.** Never commit passwords, API keys, tokens,
   private keys, Wi-Fi passphrases or anything else that grants access, including in `dotfiles/`
   and in Nix strings (they end up in the world-readable `/nix/store`). Use Bitwarden via `bws`
   at runtime. Before committing, check the diff for anything secret-looking, and stop and ask
   if unsure.
5. **Noctalia drives every app's colors.** The scheme is picked in `dotfiles/noctalia/config.toml`
   (`[theme]`, currently built-in `Tokyo-Night`) and its templates (`[theme.templates]`) write
   the colors into Hyprland, kitty, btop, GTK, Qt (qt5ct/qt6ct, `desktop.nix`), Neovim, Vesktop,
   Obsidian, Steam, Claude Code, fzf, lazygit and the Gruvbox Plus folder icons. Do not set
   colors directly in an app's config. Noctalia adds and removes its own include lines
   (`require("noctalia")` in `hyprland.lua`, `include themes/noctalia.conf` in `kitty.conf`,
   `color_theme` in `btop.conf`); leave them. Neovim loads Noctalia's `lua/matugen.lua` from
   `lua/plugins/ui/colorscheme.lua`, falling back to tokyonight; Noctalia's generated Neovim
   files are git-ignored.

## Style

- No comments by default. A comment stays only where a line would otherwise look wrong and
  someone would "fix" it, such as a workaround.
- File header: only the args used (`{ pkgs, vars, ... }:`).
- `with pkgs; [ ... ]` for package lists.
- Format with `nix fmt`.

## Working here

- The flake only sees files git tracks. `git add` new files before building.
- Verify with `nix build --no-link .#nixosConfigurations.<hostname>.config.system.build.toplevel`
  for both hosts, and compare with `nix store diff-closures /run/current-system <result>`. Do
  not build scratch test projects to check config changes.
- Edits under `dotfiles/` go live immediately. Hyprland hot-reloads, so a Lua edit that needs a
  new `vars.lua` value breaks until the rebuild. Tell the user to rebuild before testing.
- Tell the user to apply with plain `sudo nixos-rebuild switch`.
- Do not commit unless asked.
