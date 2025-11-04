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

### 🚀 Bootstrap in one command
Ready a clean box with Fisher, Starship, Atuin, Tailscale, ChezMoi, Homebrew, and dotfile links:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TuxLux40/TL40-Dots/main/scripts/postinstall/postinstall.sh)
```

**Dry run first?** Append `--dry-run` to inspect prerequisites and planned steps:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TuxLux40/TL40-Dots/main/scripts/postinstall/postinstall.sh) --dry-run
```

> The post-install entrypoint auto-detects your distro, selects the right package manager, then walks through all dependent scripts with friendly logging.

---

### 📝 Notes & expectations
- Some scripts request `sudo`; you’ll see the prompt when needed
- Have a good network connection—the bootstrap pulls binaries via `curl`
- Back up before running this against a production machine (you know the drill)

Questions, ideas, PRs? Always welcome.
