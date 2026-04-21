# dotfiles

Personal Arch-centric dotfiles. GNU Stow layout under [dotfiles/](dotfiles/), plus a bootstrap script and two opt-in helpers.

## Install (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/TuxLux40/dotfiles/main/install.sh | sh
```

Or clone and run locally:

```bash
git clone https://github.com/TuxLux40/dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install.sh
```

The installer:

1. Detects the package manager (`nala apt-get dnf pacman zypper apk xbps-install eopkg`) and installs **GNU stow** first.
2. Iterates [dotfiles/](dotfiles/) and stows each package to `$HOME`.
3. Skips `clamav` by default (needs `/etc/clamav` and root).

### Flags

| Flag | Effect |
|------|--------|
| `--dry-run` | Preview stow actions, change nothing. |
| `--adopt` | Run `stow --adopt` (move existing configs into repo). |
| `--clamav` | Also stow `clamav` to `/etc` via sudo/doas. |
| `--sftp` | Run [sftp-setup.sh](sftp-setup.sh) after stowing. |
| `--nas [PATH]` | Run [symlink-nas.sh](symlink-nas.sh) after stowing. |

### Env

| Var | Default |
|-----|---------|
| `DOTFILES_REPO` | `https://github.com/TuxLux40/dotfiles.git` |
| `DOTFILES_DIR`  | `$HOME/.dotfiles` (clone target in curl-pipe mode) |

## Use with linutil

The [dotfiles/](dotfiles/) layout is a standard GNU-stow tree, so linutil's built-in **System Setup → Dotfiles Setup** works against a clone of this repo without modification. [install.sh](install.sh) is independent — use it standalone or let linutil drive stow itself.

## Layout

- [dotfiles/](dotfiles/) — stow packages rooted at `$HOME` (exception: `clamav/` → `/etc`).
- [install.sh](install.sh) — bootstrap. Installs stow, stows packages.
- [sftp-setup.sh](sftp-setup.sh) — interactive SSHFS mount manager (systemd user units).
- [symlink-nas.sh](symlink-nas.sh) — NAS → XDG user-dirs symlinks.

## Manual stow

```bash
cd dotfiles
stow -n -v -t ~ fish      # dry-run
stow -t ~ fish            # apply
stow --adopt -t ~ fish    # absorb existing configs
stow -R -t ~ fish         # relink after changes
stow -D -t ~ fish         # unlink
```
