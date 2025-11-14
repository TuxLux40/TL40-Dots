# Scripts

This document describes each script under `scripts/` in a formal and consistent format. Commands are provided for the fish shell unless noted otherwise.

Table of Contents

1. Conventions
2. install.sh
   2.1 Overview
   2.2 Prerequisites
   2.3 Procedure
   2.4 Verification
   2.5 Notes
3. flatpaks-install.sh
   3.1 Overview
   3.2 Prerequisites
   3.3 Procedure
   3.4 Notes
4. yk-pam.sh
   4.1 Overview
   4.2 Prerequisites
   4.3 Procedure
   4.4 Verification
   4.5 Notes
5. sudo_diag.sh
   5.1 Overview
   5.2 Procedure
   5.3 Output
6. sudo_pam_rollback.sh
   6.1 Overview
   6.2 Procedure
7. openrgb-udev-install.sh
   7.1 Overview
   7.2 Procedure
   7.3 Notes
8. inprem-sdunit.sh
   8.1 Overview
   8.2 Procedure
9. pvpn-sdunit.sh
   9.1 Overview
   9.2 Procedure
   9.3 Notes
10. gnome/list_gnome_shortcuts.sh
    10.1 Overview
    10.2 Procedure
11. gnome/restore-gnome-shortcuts.sh
    11.1 Overview
    11.2 Procedure
    11.3 Notes
12. blendos/systemyaml-ymlink.sh
    12.1 Overview
    12.2 Procedure
    12.3 Behavior

---

1. Conventions

- Scripts that modify system files request `sudo` as required.
- Most scripts are idempotent; re-running them should not cause issues.
- Use `fish /path/to/script.sh` from fish, or `bash /path/to/script.sh` from bash.

---

2. install.sh

2.1 Overview

- Main post-installation environment setup that is desktop- and OS-agnostic.

  2.2 Prerequisites

- `curl`, `bash`, and an active network connection (for package installations).

  2.3 Procedure

```fish
bash ~/Projects/TL40-Dots/install.sh
# Or bootstrap remotely (clones to ~/Projects/TL40-Dots by default)
curl -fsSL https://raw.githubusercontent.com/TuxLux40/TL40-Dots/main/install.sh | bash
```

---

13. podman-postinstall.sh

13.1 Overview

- Helper to enable podman socket activation (systemd or OpenRC) after package installation.
- Ensures `podman.socket` is enabled for the system (if available) and can enable the user's rootless socket
  with `loginctl enable-linger` where appropriate.

  13.2 Prerequisites

- `podman` installed (e.g., from `config/system.yaml`) and systemd or OpenRC installed and running.

  13.3 Procedure

```fish
# Run as root to enable a system socket and (optionally) a user's rootless socket
bash ~/Projects/TL40-Dots/scripts/pkg-scripts/podman-postinstall.sh --user "${SUDO_USER:-$(whoami)}"

# Or as a user to enable user-level socket only
bash ~/Projects/TL40-Dots/scripts/pkg-scripts/podman-postinstall.sh
```

13.4 Notes

- The script is idempotent and safe to re-run.
- On non-systemd systems (OpenRC), the script will attempt an `rc-update add podman default` and start the service if available.
- If `podman.socket` is not present (e.g. special packaging), the script will warn and skip enabling the socket for that unit.

Actions performed:

- Install miscellaneous tools, Atuin, Tailscale, Starship, Zoxide, and Homebrew if missing.
- Configure shell integration for bash and fish.
- Set Fish as default shell if available.

  2.4 Verification

- Open a new terminal and confirm that the Starship prompt and Homebrew environment are active.

  2.5 Notes

- The script is safe to re-run. Homebrew shellenv lines are appended only if absent.

---

3. flatpaks-install.sh

3.1 Overview

- Parse `output/flatpaks.md` and install Flatpak applications, grouped by remote.

  3.2 Prerequisites

- `flatpak` CLI available in PATH.

  3.3 Procedure

```fish
# Dry run
bash ~/Projects/TL40-Dots/scripts/pkg-scripts/flatpaks-install.sh --dry-run

# Install
bash ~/Projects/TL40-Dots/scripts/pkg-scripts/flatpaks-install.sh
```

Options:

- `-n/--dry-run`, `-l/--list`, `-f/--force`, `-h/--help`.

  3.4 Notes

- The script is idempotent and skips already installed applications unless `--force` is specified.

---

4. yk-pam.sh

4.1 Overview

- Configure `sudo` to accept YubiKey touch (password remains as fallback), and enroll one or two keys for `pam_u2f`.

  4.2 Prerequisites

- Package: `pam-u2f` (Arch/Fedora) or `libpam-u2f` (Debian/Ubuntu).
- A compatible YubiKey connected to the system.

  4.3 Procedure

```fish
fish ~/Projects/TL40-Dots/scripts/yk-pam.sh
```

Actions performed:

- Backup `/etc/pam.d/sudo` and related files to `~/pam_u2f_backup.tgz`.
- Append `auth sufficient pam_u2f.so cue` to `/etc/pam.d/sudo` if not present.
- Create `~/.config/Yubico/u2f_keys` for the login user using `pamu2fcfg`.
- Attempt to append a second key using `pamu2fcfg -n` (optional).
- Run `scripts/sudo_diag.sh`; store log at `~/sudo_diag.log`.

  4.4 Verification

```fish
sudo -K
sudo -v
```

- A touch prompt should appear. If the key is not touched or not present, password authentication should work.

  4.5 Notes

- See `docs/yubikey-pam-u2f.md` for a detailed guide, rollback, and troubleshooting.

---

5. sudo_diag.sh

5.1 Overview

- Read-only diagnostics for sudo, PAM, U2F/YubiKey, GnuPG, and related subsystems.

  5.2 Procedure

```fish
bash ~/Projects/TL40-Dots/scripts/sudo_diag.sh
```

5.3 Output

- A timestamped log: `~/sudo_diag_plus_YYYYMMDD_HHMMSS.log`.

---

6. sudo_pam_rollback.sh

6.1 Overview

- Restore `/etc/pam.d/sudo` from the most recent backup and remove a specific `pam_u2f` authfile line if present.

  6.2 Procedure

```fish
sudo bash ~/Projects/TL40-Dots/scripts/sudo_pam_rollback.sh
```

---

7. openrgb-udev-install.sh

7.1 Overview

- Install OpenRGB udev rules and reload udev. Includes SteamOS read-only handling.

  7.2 Procedure

```fish
bash ~/Projects/TL40-Dots/scripts/openrgb-udev-install.sh
```

7.3 Notes

- Downloads a rules file and installs it under `/usr/lib/udev/rules.d/`.

---

8. inprem-sdunit.sh

8.1 Overview

- Create and enable a systemd user service for Input Remapper; add GUI autoload entry.

  8.2 Procedure

```fish
bash ~/Projects/TL40-Dots/scripts/inprem-sdunit.sh
```

---

9. pvpn-sdunit.sh

9.1 Overview

- Create and enable a systemd user service to auto-connect ProtonVPN at login.

  9.2 Procedure

```fish
bash ~/Projects/TL40-Dots/scripts/pvpn-sdunit.sh
```

9.3 Notes

- Requires `protonvpn-cli` available at `/usr/bin/protonvpn-cli`.

---

10. gnome/list_gnome_shortcuts.sh

10.1 Overview

- Export custom GNOME shortcuts to `output/gnome_shortcuts.md`.

  10.2 Procedure

```fish
bash ~/Projects/TL40-Dots/scripts/gnome/list_gnome_shortcuts.sh
```

---

11. gnome/restore-gnome-shortcuts.sh

11.1 Overview

- Restore a predefined set of GNOME shortcuts using `gsettings`.

  11.2 Procedure

```fish
bash ~/Projects/TL40-Dots/scripts/gnome/restore-gnome-shortcuts.sh
```

11.3 Notes

- Review and adjust the preset bindings in the script before running.

---

12. blendos/systemyaml-ymlink.sh

12.1 Overview

- On blendOS, create a symlink from `config/system.yaml` to `/system.yaml`.

  12.2 Procedure

```fish
sudo bash ~/Projects/TL40-Dots/scripts/blendos/systemyaml-ymlink.sh
```

12.3 Behavior

- If the OS is not blendOS (as detected via `/etc/os-release`), the script exits without changes.
