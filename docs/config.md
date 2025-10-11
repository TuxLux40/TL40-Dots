# Configurations

This document explains the files under `config/` in a structured and formal layout.

Table of Contents

1. Shell and Prompt
2. Terminal
3. System Information (fastfetch)
4. Applications
5. System Package Definition
6. Git Configuration

---

1. Shell and Prompt

1.1 `config/.bashrc`

- User Bash startup file. Symlinked by `scripts/postinstall.sh` to `~/.bashrc`.

  1.2 `config/starship.toml`

- Starship prompt configuration. Symlinked by `scripts/postinstall.sh` to `~/.config/starship.toml`.
- Provides a powerline-style prompt with Git, language runtimes, Docker context, and time.

---

2. Terminal

2.1 `config/ghostty/config`

- Configuration for the Ghostty terminal emulator. Symlinked to `~/.config/ghostty/config`.

---

3. System Information (fastfetch)

3.1 `config/fastfetch/`

- Contains:
  - `config.jsonc`, `config-compact.jsonc`, `config-v2.jsonc` (configuration variants)
  - `arch.png` (asset referenced by some themes)
- Symlinked as a directory by `scripts/postinstall.sh` to `~/.config/fastfetch`.

---

4. Applications

4.1 `config/atuin/config.toml`

- Atuin (shell history) configuration. Symlinked to `~/.config/atuin/config.toml`.

  4.2 `config/aichat/config.yaml`

- AIChat configuration. Copied to `~/.config/aichat/config.yaml` by `scripts/postinstall.sh` (not symlinked to avoid exposing secrets).

---

5. System Package Definition

5.1 `config/system.yaml`

- Comprehensive package list and configuration for blendOS tracks.
- Symlinked to `/system.yaml` by `scripts/blendos/systemyaml-ymlink.sh` on blendOS systems.

---

6. Git Configuration

6.1 `git/.gitconfig`

- User-level Git settings and aliases. May be used as a template for `~/.gitconfig`.
