# 🌌 TL40-Dots — ops-ready dotfiles & automation

TL40-Dots bundles reproducible shell environments, desktop tweaks, and automation scripts that keep my Linux workstations—and assorted homelab services—consistent across distros.

> **Why you might care:** one command bootstraps a fresh machine with Fish, Starship, Atuin, Tailscale, Docker stacks, and the dotfiles that glue it all together.

---

### 🏁 Quick start

- Skim the docs below so you know what each script configures
- Run commands from `fish` or `bash` (both are supported unless noted)
- Most scripts are idempotent—rerun them if you need to sync state

### 🧰 Interactive configurator

- Launch `./start.sh` for a raspi-config style TUI (arrow-key navigation via `whiptail`/`dialog`).
- Menu highlights: run the full postinstall stack, selectively link dotfiles, export package inventories, install helper package managers (Flatpak, Brew, cargo, paru), apply locale/shortcut presets, and still manage container or automation helpers from one place.

---

### 📦 Structure at a glance

- `config/` — terminal, shell, prompt, and app configs
- `docs/` — deep dives on scripts and setup rationale
- `docker/` — homelab service Docker compose stacks
- `git/` — user-level Git configuration
- `misc/` — helper assets (themes, udev rules, etc.)
- `output/` — generated exports (Flatpak lists, GNOME mappings)
- `scripts/` — post-install automation, Docker services, DE tooling

---

### 📚 Documentation map

- YubiKey + sudo: `docs/yubikey-pam-u2f.md`
- Script catalogue: `docs/scripts.md`
- Config reference: `docs/config.md`
- Generated outputs: `docs/output.md`
- Miscellaneous notes: `docs/misc.md`
- Git setup: `docs/git.md`
- Copilot agent instructions: `.github/copilot-instructions.md`

---

### 🚀 Install

**One-command bootstrap (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/TuxLux40/TL40-Dots/main/scripts/bootstrap/tuxlux-bootstrap.sh | bash
```

That script clones the repo into `~/git/TL40-Dots`, installs a `tuxlux` launcher into your PATH (preferring `/usr/local/bin`, falling back to `~/.local/bin`), and immediately opens the TUI configurator. From then on, just run `tuxlux` to reopen the menu.

**Manual clone:**

```bash
git clone https://github.com/TuxLux40/TL40-Dots.git && cd TL40-Dots && bash ./install.sh
```

> The post-install entrypoint auto-detects your distro, selects the right package manager, then walks through all dependent scripts with friendly logging.
