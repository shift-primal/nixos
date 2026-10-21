# nixos

My NixOS setup as a flake: Hyprland with the Noctalia shell, Home Manager as a
NixOS module, and live-editable dotfiles. It builds two machines:

| Host                 | Machine | Notes                                                       |
| -------------------- | ------- | ----------------------------------------------------------- |
| `kash-desktop-nixos` | Desktop | NVIDIA, Limine, triple boot with Windows and Arch           |
| `kash-laptop-nixos`  | Laptop  | Intel graphics, systemd-boot, LUKS, autologin into Hyprland |

Tracks `nixos-unstable`. Unfree packages are allowed.

## What's in it

- **Desktop:** Hyprland (UWSM session) configured in Lua, the
  [Noctalia](https://github.com/noctalia-dev/noctalia) shell and greeter,
  PipeWire, Bluetooth, Plymouth boot splash, xdg-desktop-portal.
- **Apps:** kitty, Neovim (LazyVim), Chrome, Vesktop, Thunderbird, yazi, btop,
  Bitwarden, Steam and others. Default apps are picked in `vars.nix`, and the
  Hyprland keybinds follow.
- **Dev:** one file per language in `home/dev/` with the toolchain, LSP,
  formatter and debugger. Neovim's Mason is turned off; Nix installs every binary.
- **Services:** Docker, Tailscale, printing (HP, mDNS discovery), fwupd,
  TeamViewer, Wireshark, Solaar.
- **Helpers:** `sudo rebuild switch|boot` (aliased `rb:switch` / `rb:boot`) and,
  on the desktop, `sudo reboot-to windows|arch|limine`. Both run without a
  password and only accept those fixed arguments.

## Layout

```
flake.nix         inputs, one nixosConfiguration per folder in hosts/
vars.nix          shared values: user, paths, locale, keyboard, cursor, default apps
hosts/<host>/     hardware config, bootloader, GPU, stateVersion
system/           NixOS modules (core, hardware, desktop, services)
home/             Home Manager modules (apps, cli, dev, desktop, shell)
pkgs/             packages that are not in nixpkgs
dotfiles/         hypr, kitty, nvim, zsh, starship, noctalia (symlinked, not copied)
```

Files under `dotfiles/` are linked into `~/.config` with `mkOutOfStoreSymlink`,
so editing them takes effect right away without a rebuild. Values the dotfiles
need from Nix (hostname, keyboard, cursor, app commands) are written to
`~/.config/nixos-vars/vars.lua` on rebuild.

[`CLAUDE.md`](CLAUDE.md) has the conventions: where new things go, style and
how to verify a build.

## Installing on a new machine

1. **Install NixOS** from the official ISO in UEFI mode. On a laptop, turn on
   disk encryption in the installer. `hosts/kash-laptop-nixos/greetd.nix`
   refuses to build autologin without LUKS, because the boot passphrase is
   then the only login.
2. **Get the repo** into the home folder (`nix-shell -p git` if git is
   missing):
   ```sh
   git clone https://github.com/shift-primal/nixos ~/nixos
   ```
3. **Add a host folder.** The folder name becomes the hostname. Copy an
   existing host and adjust:
   ```sh
   cp -r ~/nixos/hosts/kash-laptop-nixos ~/nixos/hosts/<hostname>
   nixos-generate-config --show-hardware-config > ~/nixos/hosts/<hostname>/hardware-configuration.nix
   ```
   - Set `stateVersion` in `hosts/<hostname>/vars.nix` to the value in the
     installer's `/etc/nixos/configuration.nix`.
   - Pick a bootloader in `boot.nix` and a GPU module (`nvidia.nix` / `intel.nix`).
   - If the installer set up LUKS, copy the `boot.initrd.luks.devices` lines
     from its `/etc/nixos/hardware-configuration.nix` too.
   - Add `dotfiles/hypr/hyprland/hosts/<hostname>.lua` (monitors, input) and
     `dotfiles/noctalia/hosts/<hostname>.toml` + `dotfiles/noctalia/settings/<hostname>.toml`.
   - `git add` everything: the flake only sees tracked files.
4. **Move the installer's config away** so `/etc/nixos` can become a link to
   `~/nixos`:
   ```sh
   sudo mv /etc/nixos /etc/nixos.installer
   ```
5. **First switch:**
   ```sh
   sudo nixos-rebuild switch --flake ~/nixos#<hostname>
   ```
   After this, `sudo rebuild switch` (or plain `sudo nixos-rebuild switch`) is enough.
6. **Reboot** and log in to the "Hyprland (uwsm-managed)" session.

### Using it as someone else

Change `user` in `vars.nix` (name, full name), and the keyboard, locale and
time zone if needed. Then look for the few places that still hold
machine-specific values:

- `hosts/kash-desktop-nixos/boot.nix`: Arch root UUID and the Limine entries.
- `dotfiles/noctalia/hosts/*.toml` and `dotfiles/noctalia/settings/*.toml`:
  monitor names and wallpaper paths.
- `dotfiles/hypr/hyprland/hosts/*.lua`: monitor layout.
- `home/cli/default.nix` and `home/apps/default.nix`: drop what you don't use.

## What lives outside the repo

The repo is public, so nothing secret is in it. These have to be set up by hand
after the first boot:

| What                       | How                                                                                                                             |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| SSH keys                   | Bitwarden desktop's SSH agent. Turn it on in Bitwarden's settings; zsh points `SSH_AUTH_SOCK` at `~/.bitwarden-ssh-agent.sock`. |
| Bitwarden CLIs             | `rbw config set email <email>` then `rbw login`; `bw login` for the Noctalia Bitwarden plugin.                                  |
| Secrets for scripts        | Bitwarden Secrets Manager through `bws`, with the access token supplied at runtime, never in a file here.                       |
| Tailscale                  | `sudo tailscale up`                                                                                                             |
| GitHub, Claude, Railway, … | `gh auth login`, `claude`, `railway login` and so on. Tokens stay in their own config dirs.                                     |
| Wallpapers                 | Not in the repo. The desktop expects them in `~/Pictures/wallpapers-converted`.                                                 |
| Neovim plugins             | Downloaded by lazy.nvim on first start, pinned by `dotfiles/nvim/lazy-lock.json`.                                               |
| Noctalia plugins           | Downloaded by Noctalia from the list in `dotfiles/noctalia/config.toml`.                                                        |
| Desktop: Arch and Windows  | Share the 1 GB ESP. Arch's kernel and initramfs are copied to `/boot/arch` by hand after each Arch kernel update.               |
| Firmware                   | `fwupdmgr refresh && fwupdmgr update`                                                                                           |

## Everyday use

```sh
sudo rebuild switch                       # apply changes (alias: rb:switch)
sudo rebuild boot                         # apply on next boot (alias: rb:boot)
nix flake update                          # update inputs, then rebuild
nix build --no-link .#nixosConfigurations.<hostname>.config.system.build.toplevel
nix store diff-closures /run/current-system <result>   # what a build changes
```

- Edits under `dotfiles/` apply immediately; Hyprland reloads on save.
- Changes to `.nix` files, including `vars.nix`, need a rebuild.
- Noctalia saves GUI changes to `dotfiles/noctalia/settings/<hostname>.toml`, so
  they show up in `git status`. Commit them if they should stick.
- Format Nix with `nixfmt` (settings in `treefmt.toml`).
