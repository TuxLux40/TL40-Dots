# Copilot instructions for TL40-Dots
- **Scope** personal dotfiles + automation for Linux workstations, homelab services, and desktop tooling. No compiled artifacts—everything is shell, YAML, or static config.

## Big Picture
- `install.sh` is the interactive entrypoint; it chains `scripts/pkg-scripts/*` installers, then `scripts/postinstall/dotfile-symlinks.sh`, and finally optional desktop/YubiKey prompts.
- `scripts/pkg-scripts/*` detect `OS_FAMILY`/`PKG_MANAGER` (exported by the caller) and unify package install flows across distros—mirror the pattern if you add more installers.
- Configs in `config/` are the authoritative sources; running scripts should leave the workstation matching these files and docs in `docs/`.

## Repo Layout Highlights
- `scripts/` holds idempotent maintenance scripts (Bash, fish-friendly). Subdirs: `pkg-scripts/` for installers, `postinstall/` for bootstrap helpers, `gnome/`/`kde/` for DE tweaks, `blendos/` for OS-specific hooks.
- `config/` contains material that `dotfile-symlinks.sh` links (e.g., `config/starship.toml`, `config/fish/config.fish`) or copies when secrets are possible (`config/aichat/config.yaml`).
- `docker/**/compose.yaml` are drop-in stacks assuming NAS paths like `/volume1/docker/...`; `*-run.yaml` files are reference snippets, not meant for `docker compose`.
- `docs/*.md` explain rationale and procedures—update them when behavior changes (especially `docs/scripts.md`, `docs/config.md`).
- `output/` stores generated state (Flatpak manifests, GNOME dumps, etc.); scripts should both read from and write to this tree to stay reproducible.

## Key Workflows
- Bootstrap from fish: `bash ./install.sh` (script prompts for GNOME/KDE shortcut restore and YubiKey setup; plan for non-interactive usage before changing prompts).
- Re-run only portions by calling scripts directly, e.g. `bash scripts/postinstall/dotfile-symlinks.sh`, `bash scripts/openrgb-udev-install.sh`, or `fish scripts/yk-pam.sh`.
- Flatpaks install via `bash scripts/pkg-scripts/install-flatpaks.sh` (uses `output/flatpaks.md`; supports `--dry-run`, `--list`, `FLATPAKS_MD=/path`).
- GNOME tooling reads/writes `output/gnome_*`; keep ordering deterministic like `scripts/gnome/restore-gnome-shortcuts.sh`.
- Use `--force` with `dotfile-symlinks.sh` to overwrite existing files when needed.

## Patterns & Conventions
- Shell scripts use `/usr/bin/env bash`, `set -euo pipefail`, guard rails (backups, dry-run flags, logging helpers). Follow the example in `scripts/pkg-scripts/misc-tools.sh` (with install functions like `install_rustup()` and `install_fastfetch()`) and `scripts/yk-pam.sh`.
- Fish remains the interactive shell; when documenting commands, wrap Bash scripts with `bash …` so the guidance works from fish. Avoid heredocs; prefer `printf`/`echo` pipelines.
- Symlink-by-default policy: anything safe for VCS gets a symlink; sensitive configs (AI tokens, service credentials) must be copied instead—see `dotfile-symlinks.sh` for the mapping table.
- Docker examples expect NAS-style mount roots and may share `docker.sock`; call out deviations inline to avoid accidental host-specific paths.
- Installation functions check `command -v` before installing; use temp dirs with traps for cleanup (see `install_fastfetch()` pattern).

## Integration Notes
- Homebrew setup lives in `scripts/pkg-scripts/homebrew-install.sh`; it appends shellenv lines to both Bash and Fish—maintain those conventions when touching prompt or brew logic.
- YubiKey flow (`scripts/yk-pam.sh`) creates backups (`~/pam_u2f_backup.tgz`) and emits diagnostics via `scripts/sudo_diag.sh`; keep that safety net intact when modifying PAM touches.
- KDE/GNOME helpers prefer writing structured exports in `output/`; any new desktop script should follow the same pattern for reproducibility.

## Working Expectations
- Any change that alters behavior should include matching updates in `docs/` and, when relevant, refresh files under `output/` using the provided scripts.
- Maintain idempotence: scripts may be re-run after partial failure; add preflight checks instead of assuming clean state.
- If you encounter ambiguous symlink targets, distro detection, or NAS paths, raise a NOTE in-line and confirm with the maintainer before hard-coding assumptions.
