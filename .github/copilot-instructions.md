# Copilot instructions for TL40-Dots

Purpose: help AI agents make safe, useful edits to this dotfiles + scripts + Docker repo. Favor small, idempotent changes; generate fish-shell friendly commands for docs and examples.

## Big picture
- Structure: `config/` (app/system config), `scripts/` (setup/maintenance), `docker/` (compose + run examples), `docs/` (how-tos), `output/` (generated), `git/`, `misc/`.
- Vendored configs: `config/Arch-Hyprland/Hyprland-Dots/` mirrors upstream (JaKooLit). Treat as third‑party: avoid large stylistic rewrites; keep targeted tweaks local where possible.
- NAS/Synology usage: Docker volumes typically bind under `/volume1/docker/<service>`; prefer stateless services and web UIs (no X11).

## Conventions (project‑specific)
- Shell: author scripts in bash; in docs/comments, emit fish‑safe commands (no heredocs; use printf | sudo tee).
- Idempotency: use `command -v`, `grep -q`, `mkdir -p`, `ln -sfn`, and guard repeated edits. Prefer absolute symlinks; copy files that may hold secrets/state.
- XDG: default to `$XDG_CONFIG_HOME` or `~/.config` consistently.
- Secrets: copy not symlink for files like `config/aichat/config.yaml`.

## Key workflows (with examples)
- Dotfile links: `scripts/dotfile-symlinks.sh` creates links/copies into `$HOME`/`$XDG_CONFIG_HOME`.
	- Example (fish): `bash ~/Projects/TL40-Dots/scripts/dotfile-symlinks.sh --dry-run`
- Post‑install: `scripts/postinstall.sh` sets up Homebrew (bash + fish shellenv) and ensures iptables modules load at boot. It does not manage symlinks.
	- Example (fish): `bash ~/Projects/TL40-Dots/scripts/postinstall.sh`
- Flatpaks: `scripts/install-flatpaks.sh` parses `output/flatpaks.md` and installs by remote; supports `--dry-run|--list|--force`.
	- Example (fish): `bash ~/Projects/TL40-Dots/scripts/install-flatpaks.sh --dry-run`
- YubiKey sudo (U2F): `scripts/yk-pam.sh` enrolls keys and updates PAM; diagnostics in `scripts/sudo_diag.sh`; rollback via `scripts/sudo_pam_rollback.sh`.
	- Verify: `sudo -K && sudo -v` (expect touch prompt; password fallback remains).
- GNOME shortcuts: export with `scripts/gnome/list_gnome_shortcuts.sh`, restore with `scripts/gnome/restore-gnome-shortcuts.sh`.
- Docker services: `docker/<service>/compose.yaml` or `*-run.yaml`. On NAS, mount under `/volume1/docker/<service>`; use `restart: unless-stopped` and explicit `container_name`.

## Patterns to reuse
- Script scaffold: `set -euo pipefail`, `usage()`, feature detection, idempotent file ops, friendly logs (icons/colors like in `dotfile-symlinks.sh`).
- Symlinks/copies: replicate helpers from `scripts/dotfile-symlinks.sh` (`ln -sfn`, `cp -u`, canonicalize with `readlink -f`).
- Fish‑safe file writes in docs/scripts: `printf "line\n" | sudo tee /etc/example.conf > /dev/null`.

## Integration points
- AICLI: `config/aichat/config.yaml` (copied, not linked); local LLMs via Ollama are referenced.
- System package list: `config/system.yaml` (BlendOS); keep references aligned with `docs/config.md`.
- Hyprland: upstream docs/scripts live under `config/Arch-Hyprland/`.

## Gotchas
- GUI apps inside containers on NAS often fail (Qt/XCB). Prefer headless/web solutions.
- `scripts/install-flatpaks.sh` parses `output/flatpaks.md` with awk; keep that file’s structure stable.
- Don’t reintroduce heredocs in examples—fish shell is the default environment.

When changing behavior, update the corresponding doc in `docs/` with fish‑safe commands and note rollback steps (see sudo rollback script). Keep edits minimal in vendored Hyprland directories and document any divergence.
