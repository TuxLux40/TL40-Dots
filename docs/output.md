# Output artifacts

This document describes generated files under `output/` and how they are used.

Table of Contents

1. flatpaks_raw.yaml
2. flatpaks.md
3. gnome_shortcuts.md

---

1. flatpaks_raw.yaml

- Raw export of Flatpak applications and metadata.
- Typically produced via a command such as:
  - `flatpak list --app -d --columns=all > flatpaks_raw.yaml`

---

2. flatpaks.md

- Human-readable inventory derived from `flatpaks_raw.yaml`.
- Consumed by `scripts/install-flatpaks.sh` to reproduce installations.

---

3. gnome_shortcuts.md

- Export of custom GNOME keybindings created by `scripts/gnome/list_gnome_shortcuts.sh`.
- Use as a reference or input for restoration via `scripts/gnome/restore-gnome-shortcuts.sh` after reviewing that script’s preset.
