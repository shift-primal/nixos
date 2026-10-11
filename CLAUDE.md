# NixOS config

Flake for two hosts, `kash-nixos` (desktop) and `kash-laptop-nixos` (laptop), with
Home Manager as a NixOS module.
`/etc/nixos` links here. Apply with `sudo nixos-rebuild switch --flake ~/nixos`.

## Rules

1. **One source of truth.** A value used in more than one place lives in
   `vars.nix` (user, paths, locale, keyboard, cursor, default apps)
   and is read from there, never retyped. Per-machine values (`stateVersion`)
   live in `hosts/<hostname>/vars.nix`; `flake.nix` merges them over `vars.nix`
   and adds `hostname` from the folder name. Modules get it as the `vars`
   argument (passed through `specialArgs` and `extraSpecialArgs`). Never
   hard-code `kasper`, `/home/kasper`, the hostname or `~/nixos`; use
   `vars.user.name`, `vars.user.home`, `vars.hostname`, `vars.flakeDir`.
2. **Split by category, one concern per file.** Every folder has a
   `default.nix` that only imports its siblings. Add a feature as a new file
   and add it to that `default.nix`.
3. **Dotfiles stay live-editable.** Program configs (hypr, kitty, nvim, zsh,
   starship) live in `dotfiles/` and are linked with `mkOutOfStoreSymlink` in
   `home/dotfiles.nix`, so edits apply without a rebuild. Do not convert them to
   Home Manager `programs.<x>.settings`.
4. **Dotfiles read Nix values from `~/.config/nixos-vars/vars.lua`**, which
   `home/vars-lua.nix` generates from `vars.nix`. Hyprland loads it through
   `dotfiles/hypr/hyprland/vars.lua`. To share a new value, add it to `vars.nix`
   and to `luaVars` in `home/vars-lua.nix`, not to the Lua files.
5. **Nix installs every binary.** No Mason or other in-editor installers; Mason
   is disabled in `dotfiles/nvim/lua/plugins/lsp/mason.lua`. When Neovim needs a
   language server, formatter, linter or debugger, add it to the matching
   `home/dev/<language>.nix`.

## Layout

```
flake.nix            inputs, one nixosConfiguration per folder in hosts/
vars.nix             single source of truth (shared by all hosts)
hosts/<hostname>/    hardware-configuration.nix, vars.nix (stateVersion), boot.nix,
                     GPU drivers and other machine-only modules; imports ../../system
pkgs/                overlay of packages not in nixpkgs (pkgs/default.nix), one file each
system/              NixOS modules
  core/              boot, nix settings, locale, networking, users, base packages + EDITOR
  hardware/          audio, bluetooth
  desktop/           hyprland, portal, fonts
  services/          docker, steam
  home-manager.nix   wires home/ in for vars.user.name
home/                Home Manager modules
  apps/              GUI apps; defaults.nix installs everything in vars.apps
  cli/               terminal tools
  dev/               one file per language: toolchain + LSP + formatter + debugger
  desktop/           noctalia, cursor, theme, fonts, clipboard, media, hidden entries
  shell/             zsh (HM output goes to hm-init.zsh, sourced by dotfiles/zsh/.zshrc), integrations
  dotfiles.nix       ~/.config/<name> -> dotfiles/<name> links
  vars-lua.nix       generates ~/.config/nixos-vars/vars.lua
dotfiles/            live-edited configs
```

## Where things go

- GUI app: `home/apps/default.nix`. If it is a default app bound to a key,
  add it to `vars.apps` instead (nixpkgs attribute name). The command reaches
  the keybinds automatically through `meta.mainProgram`.
- CLI tool: `home/cli/default.nix`.
- New language: new `home/dev/<lang>.nix`, imported in `home/dev/default.nix`.
- System service or hardware: a new file in the matching `system/` folder.
  If it only applies to one machine (GPU, bootloader, monitors), put it in
  `hosts/<hostname>/` and import it from that host's `default.nix`.
- Hyprland setting for one machine (monitors, input tweaks):
  `dotfiles/hypr/hyprland/hosts/<hostname>.lua`. It loads last from `hyprland.lua`,
  so set only the keys that differ; the shared files stay as they are.
- New machine: `hosts/<hostname>/` with `default.nix`, `vars.nix`, `boot.nix`
  and a `hardware-configuration.nix` generated on that machine.
- Package not in nixpkgs: `pkgs/<name>.nix`, registered in `pkgs/default.nix`.
- New dotfile dir: put it in `dotfiles/` and add it to `links` in `home/dotfiles.nix`.

## Style

- Module header: `_:` when no args are used, otherwise only the args used
  (`{ pkgs, vars, ... }:`).
- `with pkgs; [ ... ]` for package lists.
- Comments say why, not what. Point to the other file when two files depend on
  each other (e.g. "started from autostart.lua").
- Format with `nixfmt`.

## Working here

- The flake only sees files git tracks. `git add` new files before building.
- Verify with `nix build --no-link .#nixosConfigurations.<hostname>.config.system.build.toplevel`,
  and compare against the running system with
  `nix store diff-closures /run/current-system <result>`.
- Edits under `dotfiles/` go live immediately. Hyprland hot-reloads, so a Lua
  edit that needs a new `vars.lua` value breaks until the rebuild. Tell the
  user to rebuild before testing.
- Do not commit unless asked.
