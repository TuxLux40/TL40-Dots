# Copilot Instructions for TL40-Dots

## Big Picture Architecture
- **Dotfiles repo** for reproducible Linux workstation and homelab setups across distros (Arch, Debian, Fedora).
- `install.sh` orchestrates: detects OS/package manager, runs `scripts/pkg-scripts/*` installers, symlinks configs via `scripts/postinstall/dotfile-symlinks.sh`, prompts for desktop shortcuts/YubiKey.
- Configs in `config/` are authoritative; scripts ensure workstation matches these (e.g., `config/fish/config.fish` symlinked to `~/.config/fish/config.fish`).
- Homelab services use Docker Compose in `docker/` assuming NAS paths like `/volume1/docker/...`; `*-run.yaml` are reference snippets, not runnable.

## Key Workflows
- **Full bootstrap**: `bash ./install.sh` (interactive; sets Fish as default shell, installs tools like Starship/Atuin/Tailscale).
- **Partial re-run**: Direct script calls, e.g., `bash scripts/pkg-scripts/misc-tools.sh` for packages, `bash scripts/postinstall/dotfile-symlinks.sh --force` to overwrite existing links.
- **Flatpaks**: `bash scripts/pkg-scripts/flatpaks-install.sh --dry-run` uses `output/flatpaks.md`; supports `--list`, custom `FLATPAKS_MD`.
- **GNOME/KDE**: Scripts read/write `output/gnome_*` deterministically (e.g., `scripts/gnome/restore-gnome-shortcuts.sh`).
- **YubiKey**: `fish scripts/yk-pam.sh` creates `~/pam_u2f_backup.tgz` backup; diagnostics via `scripts/sudo_diag.sh`.

## Project-Specific Patterns
- **Shell scripts**: Use `/usr/bin/env bash`, `set -euo pipefail`; idempotent with `command -v` checks; temp dirs with `trap 'rm -rf "$tmp_dir"' EXIT` (see `scripts/pkg-scripts/misc-tools.sh::install_nerd_font`).
- **Symlinking**: Safe configs symlinked (e.g., `config/starship.toml` -> `~/.config/starship.toml`); sensitive ones copied (e.g., `config/aichat/config.yaml` -> `~/.config/aichat/config.yaml`).
- **Package detection**: Source `/etc/os-release`; arrays like `debian_packages=(micro trash-cli ...)`; install via `sudo apt/pacman/dnf` (see `scripts/pkg-scripts/misc-tools.sh`).
- **Homebrew**: Appends shellenv to `~/.bashrc` and `~/.config/fish/config.fish`; maintain both when modifying.
- **Docker**: Expect NAS mounts; share `docker.sock`; call out host-specific paths inline.
- **Output generation**: Scripts both read from and write to `output/` for reproducibility (e.g., `scripts/pkg-scripts/arch-pkgs-extract.sh` updates `output/arch-packages.md`).

## Integration Points
- **Fish as interactive shell**: Wrap Bash commands with `bash ...` in docs; avoid heredocs, prefer `printf`/`echo`.
- **XDG compliance**: Use `$XDG_CONFIG_HOME` (default `~/.config`); ensure dirs exist before linking.
- **Distros**: Support Arch (pacman), Debian/Ubuntu (apt), Fedora (dnf); export `OS_FAMILY`/`PKG_MANAGER` for sub-scripts.
- **Desktop environments**: KDE/GNOME helpers export structured data to `output/`; new scripts should follow (e.g., `scripts/kde/kde-shortcuts-export.sh`).

## Working Expectations
- **Idempotence**: Scripts re-runnable after partial failure; add preflight checks, not assumptions.
- **Documentation**: Update `docs/*.md` (e.g., `docs/scripts.md`, `docs/config.md`) when behavior changes; refresh `output/` via scripts.
- **Safety**: Backups for PAM changes (YubiKey); `--dry-run` flags; warn on overwrites without `--force`.
- **Rationale**: Reference `docs/` for why decisions (e.g., symlink policy in `docs/dotfile-symlinks.md`).
