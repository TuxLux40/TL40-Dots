# Copilot instructions for TL40-Dots

Purpose: Help AI coding agents contribute safely and productively to this dotfiles/scripts repo.

## Big picture
- This repo is a personal dotfiles bundle for Linux: shell/config files under `config/`, automation under `scripts/`, docker service templates under `docker/`, docs under `docs/`, and generated artifacts under `output/`.
- There is no app build. Workflows are shell-first and idempotent where possible. Changes should be conservative, reversible, and documented.

## Directory map and roles
- `scripts/` – One-off or idempotent setup/maintenance scripts. Most are Bash, some assume fish as the interactive shell.
- `config/` – Source of truth for app configs; symlinked into `$HOME` (or copied when secrets risk exists). Examples: `starship.toml`, `ghostty/config`, `fastfetch/*.jsonc`, `atuin/config.toml`, `aichat/config.yaml` (copy, not symlink).
- `docker/**/compose.yaml` – Service-specific Compose files (paths assume a NAS-style root like `/volume1/docker/...`). Some `*-run.yaml` files are reference “docker run” snippets, not Compose.
- `docs/` – Readable guides for scripts and configs: `docs/scripts.md`, `docs/config.md`, `docs/yubikey-pam-u2f.md`, etc.
- `output/` – Generated exports (e.g., `flatpaks.md`, GNOME shortcuts). Scripts should read from or write to here, not commit machine-specific state elsewhere.

## Critical workflows (commands are run from fish unless noted)
- Post-install bootstrap: run via Bash from fish
  - fish: `bash ~/Projects/TL40-Dots/scripts/postinstall.sh`
  - Current behavior: installs Homebrew and writes `/etc/modules-load.d/iptables.conf` for `ip_tables` + `iptable_nat`. Docs mention more symlink steps—verify and align before expanding.
- Flatpak install (grouped by remote):
  - Dry run: `bash scripts/install-flatpaks.sh --dry-run`
  - Install: `bash scripts/install-flatpaks.sh` (reads `output/flatpaks.md`; override with `FLATPAKS_MD` env or path arg)
- YubiKey sudo with pam_u2f:
  - `fish scripts/yk-pam.sh` → backs up PAM, appends `auth sufficient pam_u2f.so cue`, enrolls 1–2 keys into `~/.config/Yubico/u2f_keys`, then runs diagnostics (`scripts/sudo_diag.sh`).
- GNOME shortcuts:
  - Export: `bash scripts/gnome/list_gnome_shortcuts.sh`
  - Restore: `bash scripts/gnome/restore-gnome-shortcuts.sh [--dry-run]`
- blendOS system.yaml symlink (only on blendOS):
  - `sudo bash scripts/blendos/systemyaml-symlink.sh` (note the filename spelling)

## Conventions and patterns
- Shell style: Prefer an env-based Bash shebang (e.g., `/usr/bin/env bash`), `set -euo pipefail`, small `log_*` helpers, and explicit dry-run flags. Scripts should be re-runnable and perform backups before mutating system files.
- Fish ergonomics: When documenting commands for fish, invoke Bash scripts with `bash …`. Avoid heredocs in docs; prefer `printf`/`echo` with redirection.
- Symlinks vs copies: Symlink configs that are safe for source control; copy files that may hold secrets (e.g., `config/aichat/config.yaml`).
- Paths: Docker examples often mount under `/volume1/docker/...`. Keep these explicit and consistent; call out when a local path is expected instead.
- Outputs: Write machine-specific exports to `output/` (already git-tracked for docs). Don’t emit temp files into repo root.

## Integration points
- Homebrew on Linux (linuxbrew) is accepted and configured in `postinstall.sh`. Use `eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)` for fish.
- Desktop tooling: GNOME via `gsettings`/`dconf`, YubiKey via `pam_u2f` and `pamu2fcfg`.
- Containers: Compose files per app in `docker/*`; some images need `/var/run/docker.sock` or NAS volumes. Keep comments that explain why a mapping exists.

## Examples from this repo
- Option parsing and dry-run: see `scripts/install-flatpaks.sh` (flags: `--dry-run`, `--list`, `--force`, env: `FLATPAKS_MD`).
- Safe edits to PAM: see `scripts/yk-pam.sh` (backup tarball, minimal append, rollback script `scripts/sudo_pam_rollback.sh`).
- Deterministic GNOME keys: see `scripts/gnome/restore-gnome-shortcuts.sh` (ordered apply, backup to `output/`).

## When adding/editing
- Prefer focused, idempotent scripts with clear preflight checks and `--dry-run` where feasible.
- Update `docs/scripts.md` and/or `docs/config.md` alongside behavioral changes; keep commands fish-friendly.
- Validate paths referenced in Compose and scripts exist or are parameterizable.

Questions or gaps? If something is ambiguous (e.g., symlink policy for a new config, or paths differing from `/volume1/docker`), leave a NOTE in the PR and ask for confirmation.
