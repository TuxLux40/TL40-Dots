# Copilot instructions for TL40-Dots

Goal: enable fast, safe edits to this dotfiles + scripts + Docker repo. Prefer small, idempotent changes; keep ad-hoc commands fish-shell friendly.

## Big picture
- Layout: configs (`config/`), scripts (`scripts/`), Docker manifests (`docker/`), docs (`docs/`), generated outputs (`output/`).
- Hosts include Synology DSM; Docker binds live under `/volume1/docker/<service>`; services should be restartable without manual state.
- Scripts are re-runnable across distros; avoid breaking on missing tools, use feature detection.

## Conventions
- Shell: author scripts in bash; in docs/comments, emit fish-safe commands (no heredocs; prefer printf/echo).
- Idempotency: guard with `command -v`, `grep -q`, `mkdir -p`, `ln -sf`; avoid duplicate lines on re-run.
- Secrets: copy rather than symlink (e.g., `config/aichat/config.yaml`).
- Docker: absolute binds under `/volume1/docker/...`; don’t assume X11 on Synology (see `docker/kleopatra/error.md`).

## Key files to mirror
- `scripts/postinstall.sh` – Homebrew init, shell integration, symlinks.
- `scripts/install-flatpaks.sh` – parses `output/flatpaks.md`, supports `--dry-run|--list|--force`.
- `scripts/yk-pam.sh`, `scripts/sudo_diag.sh`, `scripts/sudo_pam_rollback.sh` – PAM U2F setup/diagnostics/rollback.
- `docker/<service>/compose.yaml` – per-service compose; some folders include `*-run.yaml` as a documented docker run example.

## Workflow examples
- Baseline setup: `bash ~/Projects/TL40-Dots/scripts/postinstall.sh`
- Flatpaks: `bash ~/Projects/TL40-Dots/scripts/install-flatpaks.sh --dry-run` then run without flags to install.
- YubiKey sudo: `fish ~/Projects/TL40-Dots/scripts/yk-pam.sh`; verify with `sudo -K && sudo -v`.

## Patterns to reuse
- Script scaffold: `set -euo pipefail`, `usage()`, feature detection, idempotent file ops; format logs similar to `sudo_diag.sh`.
- Docker compose: mount `/volume1/docker/<service>:/config` (or service-specific), `restart: unless-stopped`, explicit `container_name`.
- Fish-safe writes in docs/scripts: `printf "line1\n" | sudo tee /etc/example.conf >/dev/null`.

## Gotchas
- GUI-in-container on NAS likely fails (Qt/XCB); prefer headless/web UIs.
- Keep `output/flatpaks.md` format stable (AWK in `install-flatpaks.sh` depends on it).
- Be consistent with `config/system.yaml` references; align with `docs/config.md`.

When changing behavior, update the matching doc under `docs/` with concise steps and fish-safe commands; ensure reversibility for system changes (see rollback script).
