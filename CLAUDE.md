# CLAUDE.md

Guidance for Claude Code on this repo.

## Repo purpose

Personal Arch dotfiles + stow bootstrap (`install.sh`) + two helper scripts. GNU Stow packages at repo root. `install.sh` stows to $HOME. Checkout `~/Projects/dotfiles` only. Old installer paths gone.

`.github/copilot-instructions.md` stale. Trust tree.

## Layout

- Top level dir = GNU Stow package at $HOME, mirroring target (e.g. fish/.config/fish/config.fish -> ~/.config/fish/config.fish). Exception: clamav/clamav/*.conf to /etc/clamav.

- `install.sh` — POSIX /bin/sh -e. Installs stow, stows top level packages to $HOME (skips clamav, non $HOME packages). Default repo-wins; --adopt local-wins.

- `system.yaml` — historical.

- `sftp-setup.sh` — interactive SSHFS. Installs sshfs, makes user systemd unit ~/.config/systemd/user/sshfs-<host>.service . POSIX sh.

- `symlink-nas.sh` — idempotent NAS symlinks to XDG dirs. Bash set -euo pipefail. Flags --dry-run --force --nas PATH. No clobber.

## Common operations

```bash
# Stow single package
cd ~/Projects/dotfiles && stow -t ~ fish

# Preview
stow -n -v -t ~ fish

# Adopt
stow --adopt -t ~ fish

# Re-link
stow -R -t ~ fish

# Unlink
stow -D -t ~ fish

# SSHFS
./sftp-setup.sh

# NAS
./symlink-nas.sh --dry-run
./symlink-nas.sh --nas /mnt/nas
```

No tests, lint, build.

## Conventions

- **Commits**: Conventional prefixes per .github/COMMIT_MESSAGE_GUIDELINES.md (feat: fix: docs: refactor: chore: ci: config: remove: update: etc). Imperative. Wrap 72.

- **Shell scripts**:
  - symlink-nas.sh : bash set -euo pipefail , flags, idempotent, no clobber.
  - sftp-setup.sh : POSIX sh, detect escalation, detect pkg mgr by probe order. Match for new scripts.

- **New package**: <name>/ at root mirroring home path. Hidden top level entries. install.sh skips non-hidden.

- **Secrets**: .gitignore .env* . Keep .env.example . Real untracked.

## GitHub workflows

Stale triggers on old paths. Run on **/*.md but logic dead. Flag for cleanup.
