# nixos

My NixOS setup: Hyprland with the Noctalia shell, Home Manager as a NixOS module, and
live-editable dotfiles. It builds two machines:

| Host           | Machine | Notes                                                       |
| -------------- | ------- | ----------------------------------------------------------- |
| `kash-desktop` | Desktop | NVIDIA, Limine, dual boot with Windows                      |
| `kash-laptop`  | Laptop  | Intel graphics, systemd-boot, LUKS, autologin into Hyprland |

The home server lives in its own repo,
[shift-primal/homelab](https://github.com/shift-primal/homelab).

Tracks `nixos-unstable`. Unfree packages are allowed.

## Layout

Plain NixOS modules, no frameworks. Each host's `default.nix` imports the shared files.

```
flake.nix        inputs and the two machines
vars.nix         user, locale, keyboard, cursor, default apps, SSH hosts
packages.nix     apps and CLI tools: one list
system.nix       nix settings, boot, locale, users, network, SSH, Tailscale, nix-ld
desktop.nix      Hyprland, greeter, Noctalia, portal, keyring, plymouth, fonts, GTK/Qt theme
hardware.nix     audio, Bluetooth, printing, Logitech, i2c, EasyEffects
dev.nix          Docker, Wireshark, Rider and .NET, global dev tools
home.nix         Home Manager: zsh, git, every dotfile link, vars.lua for Hyprland
hosts/<host>/    hostname, stateVersion, bootloader, GPU, hardware-configuration.nix
pkgs/            packages not in nixpkgs (nixfmt wrapper, oxfmt with Astro support)
dotfiles/        configs linked into ~/.config, edited live
```

## Installing things

- **An app or CLI tool:** add its nixpkgs name to `packages.nix`, then
  `sudo nixos-rebuild switch`. Search names at <https://search.nixos.org/packages>.
- **A default app bound to a key** (terminal, editor, browser, ...): change it in `vars.nix`.
  The Hyprland keybinds follow.
- **A dev tool** (runtime, language server, formatter, linter): add it to `dev.nix`, then
  rebuild.
- **Something just for now:** `nix shell nixpkgs#<name>`.

## Dev tools

Nix installs node, pnpm, python, uv, go, rust and the language servers, formatters and linters
listed in `dev.nix`. They are on PATH everywhere, so a stray `foo.ts` gets its language server,
and Neovim sees the same tools. `nix flake update` and a rebuild update them.

- A project that needs its own versions gets a dev shell: `dev init node` in the project
  (templates in `templates/`, else `the-nix-way/dev-templates`). For `node` it also copies the
  global oxlint and oxfmt configs from `dotfiles/oxc` in, unless the project has its own. direnv enters the shell on `cd`
  (nix-direnv caches it), and its tools come before the global ones on PATH. Shortcuts
  (`dotfiles/zsh/.zshrc`): `dev new <name> <template>` makes `~/proj/<name>` with a git repo and
  the shell, `dev <name>` jumps to a project, `dev ls` lists the templates, and plain `dev` runs
  `nix develop`.
- A project's JS tools (typescript, oxlint, oxfmt) go in its `package.json` as devDependencies.
- Python packages go in a uv project (`uv add`), not a global `pip install`.
- JS/TS formatting and linting is oxfmt and oxlint by default. Repos with a `biome.json` use
  biome instead.
- oxfmt, oxlint, tombi, stylua and ruff read a global config from `~/.config` (linked from
  `dotfiles/oxc`, `tombi`, `stylua`, `ruff`) when a project has none of its own.

## Installing on a new machine

1. **Install NixOS** from the official ISO in UEFI mode. On a laptop, turn on disk
   encryption: the laptop config refuses autologin without LUKS.
2. **Get the repo:** `git clone https://github.com/shift-primal/nixos ~/nixos`
   (`nix-shell -p git` if git is missing).
3. **Add a host folder:**
    ```sh
    cp -r ~/nixos/hosts/kash-laptop ~/nixos/hosts/<hostname>
    nixos-generate-config --show-hardware-config > ~/nixos/hosts/<hostname>/hardware-configuration.nix
    ```
    - In its `default.nix`, set `networking.hostName`, `system.stateVersion` (from the
      installer's `/etc/nixos/configuration.nix`), the bootloader and GPU settings.
    - Add the hostname to the list in `flake.nix` and to `hosts` in `vars.nix`.
    - If the installer set up LUKS, copy the `boot.initrd.luks.devices` lines from its
      `/etc/nixos/hardware-configuration.nix`.
    - Add `dotfiles/hypr/hyprland/hosts/<hostname>.lua` (monitors, input),
      `dotfiles/noctalia/hosts/<hostname>.toml` and `dotfiles/noctalia/settings/<hostname>.toml`.
    - `git add` everything: the flake only sees tracked files.
4. **Move the installer's config away** so `/etc/nixos` can link to `~/nixos`:
   `sudo mv /etc/nixos /etc/nixos.installer`
5. **First switch:** `sudo nixos-rebuild switch --flake ~/nixos#<hostname>`. After that, plain
   `sudo nixos-rebuild switch` is enough.
6. **Reboot** and log in to the "Hyprland (uwsm-managed)" session.

### Using it as someone else

Change `user` in `vars.nix`, and the keyboard, locale and time zone if needed. Then check:

- `hosts/kash-desktop/default.nix`: the Limine entries.
- `dotfiles/noctalia/hosts/*.toml` and `dotfiles/noctalia/settings/*.toml`: monitor names and
  wallpaper paths.
- `dotfiles/hypr/hyprland/hosts/*.lua`: monitor layout.
- `packages.nix`: drop what you don't use.

## What lives outside the repo

These have to be set up by hand after the first boot:

| What                       | How                                                                                                                             |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| SSH keys                   | Bitwarden desktop's SSH agent. Turn it on in Bitwarden's settings; zsh points `SSH_AUTH_SOCK` at `~/.bitwarden-ssh-agent.sock`. |
| Bitwarden CLIs             | `rbw config set email <email>` then `rbw login`; `bw login` for the Noctalia Bitwarden plugin.                                  |
| Secrets for scripts        | Bitwarden Secrets Manager through `bws`, with the access token supplied at runtime, never in a file here.                       |
| Tailscale                  | `sudo tailscale up`                                                                                                             |
| GitHub, Claude, Railway, … | `gh auth login`, `claude`, `railway login` and so on. Tokens stay in their own config dirs.                                     |
| Wallpapers                 | Not in the repo. The desktop expects them in `~/Pictures/wallpapers`.                                                           |
| Neovim plugins             | Downloaded by lazy.nvim on first start, pinned by `dotfiles/nvim/lazy-lock.json`.                                               |
| Noctalia plugins           | Downloaded by Noctalia from the list in `dotfiles/noctalia/config.toml`.                                                        |
| Firmware                   | `fwupdmgr refresh && fwupdmgr update`                                                                                           |

## Everyday use

```sh
sudo nixos-rebuild switch                 # apply changes (also: sudo rebuild switch, rb:switch)
sudo rebuild boot                         # apply on next boot (alias: rb:boot)
nix flake update                          # update inputs, then rebuild
homelab:switch                            # pull and switch the home server
sudo reboot-to windows|limine             # desktop: reboot into another OS
```

- Edits under `dotfiles/` apply immediately; Hyprland reloads on save.
- Changes to `.nix` files, including `vars.nix`, need a rebuild.
- Colors come from Noctalia: pick a scheme in its settings (Theme) and every app follows.
- Noctalia saves GUI changes to `dotfiles/noctalia/settings/<hostname>.toml`, so they show up
  in `git status`. Commit them if they should stick.
- Format Nix with `nix fmt`.
- Before a rebuild, `nix build --no-link .#nixosConfigurations.<host>.config.system.build.toplevel`
  and `nix store diff-closures /run/current-system <result>` show what would change.
