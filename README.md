# TL40-Dots

Personal dotfiles, scripts, and configuration files for Linux desktops. The repository contains reproducible setup scripts, desktop environment helpers, and application configurations.

This README provides an overview and links to concise documentation for each area of the repository.

## Quick start

- Review the documentation linked below before running any script.
- Prefer running scripts directly in fish or bash as noted in each document.
- Many scripts are idempotent and safe to re-run; details are documented per script.

## Repository structure

- `config/` – Application and system configuration files (shell, prompts, terminal, fastfetch, system package list).
- `docs/` – Documentation for scripts and configuration in this repository.
- `git/` – Git configuration (per-user `.gitconfig`).
- `misc/` – Auxiliary files (for example udev rules, theme notes).
- `output/` – Generated artifacts (Flatpak inventory, GNOME shortcuts export).
- `scripts/` – Setup and maintenance scripts (post-install, Flatpak, PAM/U2F, GNOME, services).

## Documentation

- YubiKey + sudo (pam_u2f): `docs/yubikey-pam-u2f.md`
- Scripts: `docs/scripts.md`
- Configuration files: `docs/config.md`
- Output artifacts: `docs/output.md`
- Miscellaneous files: `docs/misc.md`
- Git settings: `docs/git.md`

## Notes

- Commands in documentation use fish where relevant. If you use bash, adjust syntax accordingly.
- Some scripts require elevated privileges; prompts will indicate when `sudo` is needed.
