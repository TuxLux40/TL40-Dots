# 🌌 TL40-Dots — ops-ready dotfiles & automation

TL40-Dots bundles reproducible shell environments, desktop tweaks, and automation scripts that keep my Linux workstations—and assorted homelab services—consistent across distros.

> **Why you might care:** one command bootstraps a fresh machine with Fish, Starship, Atuin, Tailscale, ChezMoi, Docker stacks, and the dotfiles that glue it all together.

---

### 🏁 Quick start

- Skim the docs below so you know what each script configures
- Run commands from `fish` or `bash` (both are supported unless noted)
- Most scripts are idempotent—rerun them if you need to sync state

---

### 📦 Structure at a glance

- `config/` — terminal, shell, prompt, and app configs
- `docs/` — deep dives on scripts and setup rationale
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

### 🚀 Bootstrap

Get Fisher, Starship, Atuin, Tailscale, ChezMoi, Homebrew, and the dotfile links in place:

```bash
git clone https://github.com/TuxLux40/TL40-Dots.git "${TL40_DOTS_DIR:-~/Projects/TL40-Dots}" && bash "${TL40_DOTS_DIR:-~/Projects/TL40-Dots}/scripts/postinstall/postinstall.sh"
```

Already cloned the repo? Pull the latest changes, then rerun the script to re-sync.

You can point the checkout elsewhere by setting `TL40_DOTS_DIR`, or switch remotes/branches with `TL40_DOTS_REPO` / `TL40_DOTS_BRANCH` before running the script.

> The post-install entrypoint auto-detects your distro, selects the right package manager, then walks through all dependent scripts with friendly logging.