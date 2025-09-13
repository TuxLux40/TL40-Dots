My dotfiles to be linked into the home folder with GNU Stow.

## Configs in this repo

- `aichat`
- `atuin`
- `burn-my-windows`
- `gsnap`
- `guake`
- `kitty`
- `starship`
- `.bash.rc`
- `BlendOS system.yaml`

## Flatpak Installation

The file `./pkg_lists/flatpaks.yaml` lists desired Flatpak applications.

Use the helper script `pkg_lists/install_flatpaks.sh` to install them.

### Usage

```bash
cd pkg_lists
./install_flatpaks.sh       # Install (user entries first, rest system)
./install_flatpaks.sh --dry-run
```

### Notes

- Script is intentionally minimal: only `--dry-run` supported.
- Lines with `install: user` are installed in user scope, all others system-wide.
- Duplicate IDs are ignored (first occurrence wins).
