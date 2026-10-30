# nixos

My NixOS setup as a flake: Hyprland with the Noctalia shell, Home Manager as a
NixOS module, and live-editable dotfiles. It builds three machines:

| Host                 | Machine           | Notes                                                       |
| -------------------- | ----------------- | ----------------------------------------------------------- |
| `kash-desktop` | Desktop           | NVIDIA, Limine, triple boot with Windows and Arch           |
| `kash-laptop`  | Laptop            | Intel graphics, systemd-boot, LUKS, autologin into Hyprland |
| `kash-homelab` | HP ProDesk 400 G3 | Headless server: Komodo, Caddy, media, photos, files, backups |

Tracks `nixos-unstable`. Unfree packages are allowed.

## What's in it

- **Desktop:** Hyprland (UWSM session) configured in Lua, the
  [Noctalia](https://github.com/noctalia-dev/noctalia) shell and greeter,
  PipeWire, Bluetooth, Plymouth boot splash, xdg-desktop-portal.
- **Apps:** kitty, Neovim (LazyVim), Chrome, Vesktop, Thunderbird, yazi, btop,
  Bitwarden, Steam and others. Default apps are picked in `modules/flake/vars.nix`, and the
  Hyprland keybinds follow.
- **Dev:** a dev shell template per language in `templates/` (toolchain, LSP,
  formatter, debugger), loaded per project by direnv. Neovim's Mason is turned
  off; Nix installs every binary. See [Dev environments](#dev-environments).
- **Services:** Docker, Tailscale, printing (HP, mDNS discovery), fwupd,
  Wireshark, Solaar. SSH on every host is key-only and reachable only over
  Tailscale; the authorized keys are in `vars.user.sshKeys`.
- **Homelab:** [Komodo](https://komo.do) for deploys and Caddy in front of it
  (`modules/homelab/`), Jellyfin and a streaming stack, Immich, OpenCloud,
  Pocket ID, nightly restic backups, plus a 4 TB data disk at `/mnt/data`.
- **Helpers:** `sudo rebuild switch|boot [host]` (aliased `rb:switch` / `rb:boot`;
  the host defaults to the hostname) and, on the desktop,
  `sudo reboot-to windows|arch|limine`. Both run without a password and only
  accept those fixed arguments, or a host the flake defines.

## Layout

Dendritic: built with [flake-parts](https://flake.parts), and every file under
`modules/` is a module imported automatically by
[import-tree](https://github.com/vic/import-tree). There are no import lists;
paths containing `/_` are skipped, which keeps `_hardware-configuration.nix` out.

Files add to _aspects_ (`flake.modules.nixos.<aspect>` and
`flake.modules.homeManager.<aspect>`), and several files can feed the same
aspect. There are three roles, one folder each: `common` (every host),
`desktop` (GUI machines) and `homelab` (the server), plus one aspect per host.
Inside a role, files are grouped by use case (`desktop/session/`,
`homelab/media/`, ...). Each NixOS aspect pulls in its Home Manager side, so a
host only lists NixOS aspects:

| Host           | Aspects               |
| -------------- | --------------------- |
| `kash-desktop` | `common`, `desktop`   |
| `kash-laptop`  | `common`, `desktop`   |
| `kash-homelab` | `common`, `homelab`   |

Shared values (user, paths, locale, keyboard, cursor, default apps, SSH keys)
live once in `modules/flake/vars.nix` as `config.vars`. Per-machine values
(`networking.hostName`, `system.stateVersion`) are set in the host's
`default.nix`.

```
flake.nix         inputs, mkFlake over modules/
modules/flake/    flake-parts setup, shared values (vars.nix), packages and templates outputs
modules/common/   every host: nix/, system/, network/, shell/, CLI tools, Home Manager, sops-nix
modules/desktop/  GUI machines: session/, hardware/, apps/, theming/, dev/ (editor tooling, Docker)
modules/homelab/  the server: edge/ (Caddy, tunnel), apps/ (Komodo, Immich, ...), media/, ops/
modules/hosts/    one folder per machine: aspect list, hardware, bootloader, GPU
templates/        per-project dev shells (node, python, rust, go, c, dotnet)
pkgs/             packages that are not in nixpkgs
secrets/          sops-encrypted secrets (recipients in .sops.yaml)
dotfiles/         hypr, kitty, nvim, zsh, starship, noctalia (symlinked, not copied)
```

Files under `dotfiles/` are linked into `~/.config` with `mkOutOfStoreSymlink`,
so editing them takes effect right away without a rebuild. Values the dotfiles
need from Nix (hostname, keyboard, cursor, app commands) are written to
`~/.config/nixos-vars/vars.lua` on rebuild.

[`CLAUDE.md`](CLAUDE.md) has the full conventions.

## Adding things

One feature is one file, with its NixOS and Home Manager parts together (see
`modules/desktop/dev/docker.nix`). New files have to be `git add`ed before a build sees
them.

- **Feature:** a new file in the role's use-case folder that adds to
  `flake.modules.nixos.<aspect>` and/or `flake.modules.homeManager.<aspect>`.
  Values used in more than one place go in `modules/flake/vars.nix`.
- **CLI tool:** `modules/common/cli.nix` (every host) or `modules/desktop/dev/cli.nix`
  (desktops only). **GUI app:** `modules/desktop/apps/apps.nix`,
  or `vars.apps` if it is a default app with a keybind.
- **Language:** a dev shell in `templates/<lang>/` with its toolchain, LSP,
  formatter and debugger, registered in `modules/flake/templates.nix`.
- **Machine-only setting** (GPU, bootloader, disks): a file in
  `modules/hosts/<hostname>/` adding to `flake.modules.nixos.<hostname>`.
  Hyprland tweaks go in `dotfiles/hypr/hyprland/hosts/<hostname>.lua`.
- **Package not in nixpkgs:** `pkgs/<name>.nix`, registered in `pkgs/default.nix`.
- **Host:** see below.

## Dev environments

Language toolchains are not installed system-wide. Each project gets its own dev
shell from a template in `templates/`:

```sh
cd ~/code/my-app
nix flake init -t ~/nixos#node     # or python, rust, go, c, dotnet
direnv allow
```

This writes a `flake.nix` with the dev shell, an `.envrc` (`use flake`) and a
`.gitignore` for `.direnv/`. From then on the shell loads when you `cd` into the
project and unloads when you leave; nix-direnv caches it, so re-entering is
instant, and keeps it safe from garbage collection. Change the package list in
the project's `flake.nix` to suit it. Start Neovim from inside the project so it
sees the project's language servers. Tooling for configs and scripts (nix, lua,
shell, toml, markdown, docker) stays global in `modules/desktop/dev/`.

## Installing on a new machine

1. **Install NixOS** from the official ISO in UEFI mode. On a laptop, turn on
   disk encryption in the installer. `modules/hosts/kash-laptop/greetd.nix`
   refuses to build autologin without LUKS, because the boot passphrase is
   then the only login.
2. **Get the repo** into the home folder (`nix-shell -p git` if git is
   missing):
   ```sh
   git clone https://github.com/shift-primal/nixos ~/nixos
   ```
3. **Add a host folder.** Copy an existing host and adjust:
   ```sh
   cp -r ~/nixos/modules/hosts/kash-laptop ~/nixos/modules/hosts/<hostname>
   nixos-generate-config --show-hardware-config > ~/nixos/modules/hosts/<hostname>/_hardware-configuration.nix
   ```

   - In its `default.nix`, set `hostname`, pick the aspects, and set
     `system.stateVersion` to the value in the installer's
     `/etc/nixos/configuration.nix`.
   - Pick a bootloader in `boot.nix` and a GPU module (`nvidia.nix` / `intel.nix`).
   - A server imports `common` (plus `homelab` for these services); copy
     `kash-homelab` instead and skip
     the Hyprland and Noctalia files below.
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
   If the hostname doesn't match a config yet, `rb:switch <hostname>` names it once.
6. **Reboot** and log in to the "Hyprland (uwsm-managed)" session.
7. **Secrets:** add the new host's age key to `.sops.yaml` (see
   [Secrets](#secrets)), and its SSH public key to `vars.user.sshKeys` if it
   should SSH into the others.

### Using it as someone else

Change `user` in `modules/flake/vars.nix` (name, full name), and the keyboard, locale and
time zone if needed. Then look for the few places that still hold
machine-specific values:

- `modules/hosts/kash-desktop/boot.nix`: Arch root UUID and the Limine entries.
- `dotfiles/noctalia/hosts/*.toml` and `dotfiles/noctalia/settings/*.toml`:
  monitor names and wallpaper paths.
- `dotfiles/hypr/hyprland/hosts/*.lua`: monitor layout.
- `modules/common/cli.nix`, `modules/desktop/dev/cli.nix` and `modules/desktop/apps/apps.nix`: drop what you don't use.

## Secrets

The repo is public, so no plaintext secret goes in it, in Nix strings or in
`dotfiles/`. Secrets the system needs are committed encrypted with
[sops-nix](https://github.com/Mic92/sops-nix) under `secrets/` and decrypted at
activation into `/run/secrets`, never into the Nix store.

| File                            | Read by                      |
| ------------------------------- | ---------------------------- |
| `secrets/hosts/<hostname>.yaml` | that host (its default file) |
| `secrets/common.yaml`           | every host                   |
| `secrets/home.yaml`             | Home Manager                 |

Every file is also encrypted to my personal age key (private half in Bitwarden),
so I can edit all of them from any machine. Hosts decrypt with an age key
derived from their SSH host key, so there is no key file to copy.

- **Add a host as a recipient:** on that host, run
  `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`, add the result under `keys:`
  and to its rules in `.sops.yaml`, then `sops updatekeys secrets/<file>.yaml`
  for each file it should read.
- **Add a secret:** `sops secrets/hosts/<hostname>.yaml` (or `common.yaml`) to
  edit the value, and declare it in the feature that uses it with
  `sops.secrets."<name>" = { };`, or `sops.templates` for an env file.
- **Before committing**, check that the file's values read `ENC[...]` and that
  it ends with `sops:` metadata.

`sops`, `age` and `ssh-to-age` are installed on every host.

## Backups (homelab)

`modules/homelab/ops/backup.nix` runs restic every night around 03:00 to a private R2
bucket. It copies `/var/lib/docker/volumes`, the paths features add to
`homelab.backup.paths` (Komodo's keys and data), and database dumps taken just
before: Komodo's MongoDB, plus every container labelled `homelab.backup=postgres`
(`pg_dumpall`). It keeps 7 daily, 5 weekly and 12 monthly snapshots, and checks
2% of the stored data after each run. Projects whose database is on Neon back up
on their own; nothing of theirs is on the box.

The repository password (`restic/password` in sops) is also in Bitwarden.
Without it no snapshot can be read.

```sh
sudo systemctl start restic-backups-offsite   # run now
journalctl -u restic-backups-offsite -n 50    # last run
sudo restic-offsite snapshots                 # what's stored
sudo restic-offsite restore latest --target /tmp/restore --include /var/lib/komodo-core
```

To restore Komodo's database, stop `docker-komodo-core`, then
`docker exec -i komodo-mongo sh -c 'mongorestore --drop --archive --gzip -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin' < komodo-mongo.archive.gz`.

## What lives outside the repo

These have to be set up by hand after the first boot:

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
- Changes to `.nix` files, including `modules/flake/vars.nix`, need a rebuild.
- Noctalia saves GUI changes to `dotfiles/noctalia/settings/<hostname>.toml`, so
  they show up in `git status`. Commit them if they should stick.
- Format Nix with `nixfmt` (settings in `treefmt.toml`).
