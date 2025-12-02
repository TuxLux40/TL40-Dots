# 🌌 TL40-Dots — ops-ready dotfiles & automation

TL40-Dots bundles reproducible shell environments, desktop tweaks, and automation scripts that keep my Linux workstations—and assorted homelab services—consistent across distros.

> **Why you might care:** one command bootstraps a fresh machine with Fish, Starship, Atuin, Tailscale, Docker stacks, and the dotfiles that glue it all together.

---

### 🏁 Quick start

- Skim the docs below so you know what each script configures
- Run commands from `fish` or `bash` (both are supported unless noted)
- Most scripts are idempotent—rerun them if you need to sync state

---

### 📦 Structure at a glance

- `config/` — terminal, shell, prompt, and app configs (including container compose files)
- `git/` — user-level Git configuration
- `misc/` — helper assets (udev rules, etc.)
- `output/` — generated exports (Flatpak lists, GNOME mappings, package lists)
- `scripts/` — post-install automation, system setup, desktop environment tooling
  - `desktop/` — GNOME and KDE specific scripts
  - `distro/` — distribution-specific configurations
  - `fixes/` — system fixes and workarounds
  - `hardware/` — hardware-specific setup scripts
  - `lib/` — shared library functions
  - `pkg-scripts/` — package installation scripts
  - `postinstall/` — post-installation configuration
  - `system-setup/` — system-level setup scripts
- `styling/` — color schemes and theming configs
- `ansible/` — Ansible playbooks for automation
- `security-tools.ansible.yml` — security tools setup playbook

---

### 📚 Key scripts and features

- **YubiKey PAM setup:** `scripts/system-setup/yk-pam.sh`
- **Package management:** Scripts in `scripts/pkg-scripts/` for installing base tools, desktop packages, Homebrew, etc.
- **Desktop environment:** GNOME and KDE shortcuts and configurations in `scripts/desktop/`
- **System fixes:** AppArmor optimization, Tailscale DNS fix, Raspberry Pi HDMI fix in `scripts/fixes/`
- **Hardware setup:** OpenRGB udev rules, AMD Vulkan setup in `scripts/hardware/`
- **Container configs:** Docker Compose files for various services in `config/containers/`
- **Security:** ClamAV and Wazuh configurations via Ansible playbook

---

### 🚀 Install

For install run:

```bash
git clone https://github.com/TuxLux40/TL40-Dots.git && cd TL40-Dots && bash ./install.sh
```

> The post-install entrypoint auto-detects your distro, selects the right package manager, then walks through all dependent scripts with friendly logging.
