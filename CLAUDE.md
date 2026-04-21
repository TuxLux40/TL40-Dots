# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo purpose

Personal Arch-centric dotfiles and a pair of workstation-bootstrap scripts. The repo is mid-restructure: the old installer (`install.sh`, `scripts/`, `config/`, `ansible/`) has been deleted in the working tree and replaced with a GNU Stow-based `dotfiles/` layout plus two standalone shell scripts at the root. Future work happens against the new layout — treat the deleted paths as gone, not as code to resurrect.

`.github/copilot-instructions.md` still describes the old installer and is stale. If a task contradicts that file and the current tree, trust the tree.

## Layout

- `dotfiles/` — each subdirectory is a **GNU Stow package** rooted at `$HOME`. Stow packages mirror the target layout (e.g. `dotfiles/fish/.config/fish/config.fish` → `~/.config/fish/config.fish`). `dotfiles/clamav/clamav/*.conf` is the exception: those link into `/etc/clamav` and need a root stow target, not `$HOME`.
- `dotfiles/system.yaml` — blendOS package manifest (historical; kept for package-list reference, not consumed by any script in the current tree).
- `sftp-setup.sh` — interactive SSHFS mount manager. Installs `sshfs` via the detected package manager, generates a systemd **user** unit at `~/.config/systemd/user/sshfs-<host>.service`, enables it. Supports add/remove flows. POSIX `/bin/sh -e`.
- `symlink-nas.sh` — idempotent script that symlinks NAS paths (default `$HOME/nas`) into XDG user dirs (`~/Documents`, `~/Pictures`, `~/Music`, `~/Videos`, `~/Downloads`) using the `NAS-<source>` naming convention. Bash, `set -euo pipefail`. Flags: `--dry-run`, `--force`, `--nas PATH`. Refuses to clobber real files/dirs; only replaces existing symlinks when `--force`.

## Common operations

```bash
# Stow a single package into $HOME
cd dotfiles && stow -t ~ fish

# Preview (dry run)
stow -n -v -t ~ fish

# Adopt existing configs into the repo (moves files into dotfiles/<pkg>, then links back)
stow --adopt -t ~ fish

# Re-link after changes
stow -R -t ~ fish

# Unlink
stow -D -t ~ fish

# SSHFS mount manager (interactive)
./sftp-setup.sh

# NAS symlinks
./symlink-nas.sh --dry-run
./symlink-nas.sh --nas /mnt/nas
```

No test suite, no lint config, no build step.

## Conventions

- **Commits**: Conventional prefixes per `.github/COMMIT_MESSAGE_GUIDELINES.md` (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `ci:`, `config:`, `remove:`, `update:`, etc.). Imperative mood, wrap body at 72 chars.
- **Shell scripts**:
  - `symlink-nas.sh` style: bash, `set -euo pipefail`, explicit flags, idempotent, never clobber real files.
  - `sftp-setup.sh` style: POSIX `sh`, detect `sudo`/`doas` via `ESCALATION_TOOL`, detect package manager by probing `nala apt-get dnf pacman zypper apk xbps-install eopkg` in order. Match this pattern if adding new distro-portable scripts.
- **Adding a new dotfile package**: create `dotfiles/<name>/` mirroring the home-relative target path (e.g. `dotfiles/<name>/.config/<name>/...` for XDG configs). Stow derives the symlink target from that structure — don't flatten it.
- **Secrets**: `.gitignore` blocks `.env*` globally but keeps `*.env.example`. When adding config that references secrets, ship a `.env.example` and keep the real file untracked.

## GitHub workflows

`.github/workflows/sync-wiki.yml` and `update-readme.yml` trigger on paths (`scripts/**`, `config/**`, `output/**`, `install.sh`) that no longer exist. They'll still run on `**/*.md` changes but most of their logic is dead. Don't rely on them; flag them for cleanup if touching CI.
