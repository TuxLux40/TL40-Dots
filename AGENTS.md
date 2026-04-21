# AI Agent Guidelines — dotfiles

**Purpose**: Personal Arch-centric dotfiles repository with GNU Stow-based symlink management and bootstrap scripts. No build/test infrastructure, no CI runners.

## Layout

- **`dotfiles/`** — Each subdirectory is a [GNU Stow](https://www.gnu.org/software/stow/) package mirroring `$HOME` directory structure.
  - Example: `dotfiles/fish/.config/fish/config.fish` → `~/.config/fish/config.fish`
  - Exception: `dotfiles/clamav/clamav/*.conf` links to `/etc/clamav` (needs root stow target)
- **`sftp-setup.sh`** — Interactive SSHFS mount manager; POSIX `/bin/sh -e`
- **`symlink-nas.sh`** — Idempotent NAS symlink script; bash, `set -euo pipefail`, respects `.gitignore`

## Repository State

⚠️ **Mid-restructure**: Old installer paths (`install.sh`, `scripts/`, `config/`, `ansible/`) have been deleted from working tree. Future work uses new layout. `.github/copilot-instructions.md` is stale; trust the current file tree.

## Conventions

### Shell Scripts

- **`symlink-nas.sh` style** → bash, `set -euo pipefail`, explicit `--flags`, **never clobber real files**, only replace existing symlinks when `--force`
- **`sftp-setup.sh` style** → POSIX `sh`, detect package manager by probing `nala apt-get dnf pacman zypper apk xbps-install eopkg` in order
- Add new distro-portable scripts using `sftp-setup.sh` pattern (auto-detect OS/manager)

### Commits

Follow [.github/COMMIT_MESSAGE_GUIDELINES.md](.github/COMMIT_MESSAGE_GUIDELINES.md):

- Conventional prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `ci:`, `config:`, `remove:`, `update:`, etc.
- Imperative mood; wrap body at 72 chars

### Adding Dotfile Packages

1. Create `dotfiles/<name>/` mirroring home-relative target path
   - Example: `dotfiles/myapp/.config/myapp/config.yaml` for XDG configs
2. Stow derives symlink target from structure automatically
3. Ship `.env.example` if config references secrets; keep real `.env*` untracked (`.gitignore` blocks globally)

## Common Operations

```bash
cd dotfiles && stow -t ~ PACKAGE       # Apply
stow -n -v -t ~ PACKAGE               # Dry-run
stow --adopt -t ~ PACKAGE             # Adopt existing configs into repo
stow -R -t ~ PACKAGE                  # Re-link after changes
stow -D -t ~ PACKAGE                  # Unlink
./sftp-setup.sh                        # SSHFS manager (interactive)
./symlink-nas.sh --dry-run             # Preview NAS symlinks
```

## Key Resources

- **Detailed project info** → [CLAUDE.md](CLAUDE.md)
- **Commit guidelines** → [.github/COMMIT_MESSAGE_GUIDELINES.md](.github/COMMIT_MESSAGE_GUIDELINES.md)
- **Package list** (historical, reference only) → [dotfiles/system.yaml](dotfiles/system.yaml)

## No Build/Lint/Test

This repo has no:

- Build step
- Test suite
- Lint config
- CI workflows that are actively used

The workflows in `.github/workflows/` reference deleted paths (`scripts/**`, `config/**`) and are stale.
