# NixOS config

Flake for `kash-desktop` (desktop), `kash-laptop` (laptop) and `kash-homelab`
(homelab server), with
Home Manager as a NixOS module, in the dendritic pattern (flake-parts + import-tree).
`/etc/nixos` links here (`modules/base/flake-link.nix`). Apply with `sudo nixos-rebuild switch --flake ~/nixos`.

## Rules

1. **Every file is a flake-parts module.** Every `.nix` file under `modules/` is
   imported automatically by import-tree; there are no `default.nix` import
   lists. Paths containing `/_` are skipped, which keeps generated
   `_hardware-configuration.nix` files out. A file adds config to an _aspect_:
   `flake.modules.nixos.<aspect>` and/or `flake.modules.homeManager.<aspect>`.
   Several files feed the same aspect and merge. Aspects: `base` (every host),
   `workstation` (GUI machines), `dev`, and one per host. Each NixOS aspect
   brings its Home Manager twin (`<aspect>/home.nix`, `base/home-manager.nix`),
   so a host only lists NixOS aspects.
2. **One concern per file, whole feature in one file.** A feature that needs a
   service, a user group, packages and a dotfile link (e.g.
   `modules/dev/docker.nix`) sets all of it in one file, on both the NixOS and
   Home Manager side. Add a feature as a new file in its aspect's folder.
3. **One source of truth.** A value used in more than one place lives in
   `config.vars` (`modules/flake/vars.nix`: user, paths, locale, keyboard,
   cursor, default apps) and is read from there, never retyped. Read it from the
   flake-parts module around the inner one, because the inner module's `config`
   is the NixOS/HM one:
   `{ config, ... }: let inherit (config) vars; in { flake.modules.nixos.x = { pkgs, ... }: ...; }`.
   `inputs` comes the same way. There are no `specialArgs`. Per-machine values
   live in the host's `default.nix`: `networking.hostName` and
   `system.stateVersion`; Home Manager reads them through `osConfig`. Never
   hard-code `kasper`, `/home/kasper`, the hostname or `~/nixos`; use
   `vars.user.name`, `vars.user.home`, `osConfig.networking.hostName` (or
   `config.networking.hostName` in NixOS modules), `vars.flakeDir`.
4. **Dotfiles stay live-editable.** Program configs (hypr, kitty, nvim, zsh,
   starship) live in `dotfiles/` and are linked with `mkOutOfStoreSymlink`
   through the `dotfiles.links` option (`modules/base/dotfiles.nix`); each
   feature adds its own entries. Edits apply without a rebuild. Do not convert
   them to Home Manager `programs.<x>.settings`.
5. **Dotfiles read Nix values from `~/.config/nixos-vars/vars.lua`**, which
   `modules/workstation/vars-lua.nix` generates from `config.vars`. Hyprland
   loads it through `dotfiles/hypr/hyprland/vars.lua`. To share a new value, add
   it to `modules/flake/vars.nix` and to `luaVars` in
   `modules/workstation/vars-lua.nix`, not to the Lua files.
6. **Nix installs every binary.** No Mason or other in-editor installers; Mason
   is disabled in `dotfiles/nvim/lua/plugins/lsp/mason.lua`. When Neovim needs a
   language server, formatter, linter or debugger, add it to the matching
   `modules/dev/<language>.nix`.
7. **No plaintext secrets in the repo; it is public.** Never commit passwords,
   API keys, tokens, private keys, Wi-Fi passphrases, password hashes or
   anything else that grants access in plaintext. That includes `dotfiles/`,
   since everything there is tracked too. The one exception is sops-encrypted
   files under `secrets/` (recipients in `.sops.yaml`, wiring in
   `modules/secrets/sops.nix`): only commit one after checking that its values
   read `ENC[...]` and it ends with `sops:` metadata. Do not put secrets in Nix
   strings either: they end up in the world-readable `/nix/store`. Use
   `sops.secrets` / `sops.templates` (decrypted to `/run/secrets` at activation)
   or Bitwarden via `bws` at runtime. Before committing, check the diff for
   anything secret-looking, and stop and ask if unsure.

## Layout

```
flake.nix            inputs; outputs = mkFlake over (import-tree ./modules)
modules/
  flake/             systems, flake.modules option, vars option, overlay
  base/              every host: nix settings, boot basics, locale, users, ssh, tailscale,
                     rebuild, Home Manager wiring, shell, CLI tools, dotfiles.links option
  workstation/       GUI machines: Hyprland, greeter, portal, keyring, plymouth, audio,
                     bluetooth, printing, steam, apps, theming, fonts, vars.lua
  dev/               one file per language (toolchain + LSP + formatter + debugger),
                     docker, wireshark, claude skills
  server/            one aspect per service (komodo, caddy, cloudflared, backup); each adds its own Caddy
                     virtualHost and sops secrets
  secrets/           sops-nix wiring
  hosts/<hostname>/  default.nix (nixosConfiguration, aspect list, hostName, stateVersion),
                     _hardware-configuration.nix, boot.nix, GPU and other machine-only files
pkgs/                overlay of packages not in nixpkgs (pkgs/default.nix), one file each
secrets/             sops-encrypted YAML only
dotfiles/            live-edited configs
```

## Where things go

- GUI app: `modules/workstation/apps.nix`. If it is a default app bound to a key,
  add it to `vars.apps` instead (nixpkgs attribute name). The command reaches
  the keybinds automatically through `meta.mainProgram`.
- CLI tool: `modules/base/cli.nix`.
- New language: new `modules/dev/<lang>.nix`.
- System service or hardware: a new file in the matching aspect folder. If it
  only applies to one machine (GPU, bootloader, monitors), put it in
  `modules/hosts/<hostname>/`, adding to `flake.modules.nixos.<hostname>`.
- New aspect: write files that add to it, plus a `home.nix` like
  `modules/dev/home.nix` if it has a Home Manager side. Hosts import it by name.
- Secret: declare it in the feature that uses it (`sops.secrets."<name>" = { };`,
  or `sops.templates` for env files) and add the value with
  `sops secrets/hosts/<hostname>.yaml` (`common.yaml` for every host).
- Hyprland setting for one machine (monitors, input tweaks):
  `dotfiles/hypr/hyprland/hosts/<hostname>.lua`. It loads last from `hyprland.lua`,
  so set only the keys that differ; the shared files stay as they are.
- New machine: copy a folder in `modules/hosts/`, name it after the hostname, set
  `hostname`, `system.stateVersion` and the aspect list in its `default.nix`, and
  save the `hardware-configuration.nix` generated on that machine there as
  `_hardware-configuration.nix`. First switch:
  `sudo nixos-rebuild switch --flake ~/nixos#<hostname>`; move the installer's
  `/etc/nixos` away so the link can be created. For secrets, add its host key to
  `.sops.yaml` and run `sops updatekeys` on the files it should read.
- Web app on the homelab: an entry in `homelab.apps` (`modules/hosts/kash-homelab/apps.nix`).
  `modules/server/komodo/apps.nix` turns it into a Komodo Stack (Resource Sync
  "homelab") and a Caddy vhost; move its domain onto the tunnel with `cutover <domain>`.
  Its secret env vars (`secrets`) come from sops keys `apps/<app>/<key>`.
- Media stack setting that lives in an app's own database (Jellyfin libraries and users, indexers,
  Bazarr languages, Seerr defaults, the links between the apps): `modules/server/media/configure.nix`,
  applied through each app's API by `_configure.py` (the `media-configure` service). Quality
  profiles come from the TRaSH Guides via `modules/server/media/recyclarr.nix`.
- Package not in nixpkgs: `pkgs/<name>.nix`, registered in `pkgs/default.nix`.
- New dotfile dir: put it in `dotfiles/` and add it to `dotfiles.links` in the
  feature that uses it.

## Style

- File header: `_:` when no args are used, otherwise only the args used
  (`{ config, inputs, ... }:`). Same for the inner NixOS/HM module.
- `with pkgs; [ ... ]` for package lists.
- Comments say why, not what. Point to the other file when two files depend on
  each other (e.g. "started from autostart.lua").
- Format with `nixfmt`.

## Working here

- The flake only sees files git tracks. `git add` new files before building;
  import-tree does not see untracked files either.
- Verify with `nix build --no-link .#nixosConfigurations.<hostname>.config.system.build.toplevel`,
  and compare against the running system with
  `nix store diff-closures /run/current-system <result>`.
- Edits under `dotfiles/` go live immediately. Hyprland hot-reloads, so a Lua
  edit that needs a new `vars.lua` value breaks until the rebuild. Tell the
  user to rebuild before testing.
- Do not commit unless asked.
