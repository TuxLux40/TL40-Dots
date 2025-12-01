# Script Structure Analysis - TL40-Dots

## Aktuelle Ordnerhierarchie - Bewertung

### ✅ **Gut organisiert:**

#### **`pkg-scripts/`** (15 Dateien)

- **Zweck:** Paketinstallation und Software-Management
- **Bewertung:** ✅ Sehr gut - Alle Package-bezogenen Skripte an einem Ort
- Enthält: base-tools, desktop-packages, aur-packages, paru, atuin, starship, homebrew, etc.
- **Verbesserung:** Könnte in Unterordner aufgeteilt werden:
  - `pkg-scripts/core/` - base-tools, desktop-packages, aur-packages
  - `pkg-scripts/optional/` - atuin, starship, homebrew, signal, etc.

#### **`postinstall/`** (3 Dateien)

- **Zweck:** Konfiguration nach Installation
- **Bewertung:** ✅ Gut - Klare Abgrenzung zu Installation
- Enthält: dotfile-symlinks, nas-mount, nas-symlinks
- **Perfekt:** Logische Gruppierung von Post-Install Tasks

#### **`fixes/`** (4 Dateien)

- **Zweck:** Hardware/Software-spezifische Fixes
- **Bewertung:** ✅ Ausgezeichnet - Klare Kategorie für Problemlösungen
- Enthält: amd-vulkan-setup, apparmor-optimize, rpi-hdmi-fix, tailscale-dns-fix
- **Gut benannt:** Sofort klar, dass es um Fixes geht

#### **`gnome/`** & **`kde/`** (2 + 2 Dateien)

- **Zweck:** Desktop Environment-spezifische Skripte
- **Bewertung:** ✅ Perfekt - Klare Trennung nach DE
- **Alternative:** Könnte zu `desktop/gnome/` und `desktop/kde/` werden

#### **`blendos/`** (1 Datei)

- **Zweck:** BlendOS-spezifische Skripte
- **Bewertung:** ✅ Gut - Distro-spezifische Isolation
- **Konsistenz:** Ähnlich zu windows/ - gut für Multi-Distro Support

#### **`windows/`** (1 Datei)

- **Zweck:** Windows/WSL-spezifische Skripte
- **Bewertung:** ✅ Gut - Platform-spezifisch getrennt

#### **`system-setup/`** (3 Dateien)

- **Zweck:** Systemweite Konfiguration
- **Bewertung:** ⚠️ Gemischt
- Enthält: apparmor-grub-setup (UNSAFE!), locale-setup, nas-mount.service
- **Problem:** Mix aus safe/unsafe und service files
- **Vorschlag:**
  - `system-setup/` für sichere Configs
  - `system-setup/advanced/` oder `advanced/` für gefährliche Skripte

---

### ❌ **Verbesserungsbedarf - Root-Level Skripte:**

**7 Skripte direkt im scripts/ Root - sollten kategorisiert werden:**

#### 1. **`detect-os.sh`** ✅ OK im Root

- **Grund:** Wird von install.sh als Library genutzt
- **Vorschlag:** Könnte zu `lib/` oder `core/` verschoben werden
- **Alternativ:** Bleibt im Root als "wichtiges Utility"

#### 2. **`pretty-output.sh`** ✅ OK im Root

- **Grund:** Shared Library für Farb-Output
- **Vorschlag:** `lib/pretty-output.sh` oder `utils/pretty-output.sh`
- **Alternativ:** Bleibt im Root als "wichtiges Utility"

#### 3. **`openrgb-udev-install.sh`** ❌ Falsch platziert

- **Aktuell:** Root-Level
- **Sollte:** `fixes/openrgb-udev-install.sh` oder `hardware/openrgb-udev-install.sh`
- **Grund:** Hardware-spezifischer Fix, passt perfekt zu `fixes/`

#### 4. **`yk-pam.sh`** ❌ Falsch platziert

- **Aktuell:** Root-Level
- **Sollte:** `system-setup/yubikey-pam-setup.sh` oder `security/yubikey-pam.sh`
- **Grund:** Systemweite PAM-Konfiguration, Security-relevant

#### 5. **`inprem-sdunit.sh`** ❌ Unklar

- **Aktuell:** Root-Level
- **Sollte:** `system-setup/systemd/inprem-unit.sh`
- **Grund:** Systemd-Service-Setup
- **Problem:** Unklarer Name - was ist "inprem"?

#### 6. **`pvpn-sdunit.sh`** ❌ Unklar

- **Aktuell:** Root-Level
- **Sollte:** `system-setup/systemd/protonvpn-unit.sh`
- **Grund:** Systemd-Service für ProtonVPN (?)
- **Problem:** Kryptischer Name "pvpn-sdunit"

#### 7. **`example-os-usage.sh`** ✅ OK als Beispiel

- **Aktuell:** Root-Level
- **Sollte:** `examples/os-detection-usage.sh` oder kann gelöscht werden
- **Grund:** Beispiel-Code, nicht produktiv

---

## Bewertung der Organisation

### Stärken ✅

1. **Klare Kategorisierung** für die meisten Skripte
2. **pkg-scripts/** ist sehr gut strukturiert
3. **Logische Trennung** nach Zweck (fixes, postinstall, etc.)
4. **DE-spezifisch** gut getrennt (gnome/, kde/)
5. **Platform-Trennung** vorhanden (windows/, blendos/)

### Schwächen ❌

1. **7 Root-Level Skripte** - zu viele lose Dateien
2. **Unklare Benennung** (inprem-sdunit, pvpn-sdunit)
3. **system-setup/** enthält Mix aus safe/unsafe Skripten
4. **Keine lib/** oder **utils/** für Shared Code
5. **Keine examples/** für Beispiel-Code
6. **Keine hardware/** für Hardware-spezifische Skripte

---

## Empfohlene neue Struktur

```
scripts/
├── lib/                          # Shared libraries & utilities
│   ├── detect-os.sh             # OS detection library
│   └── pretty-output.sh         # Color output functions
│
├── pkg-scripts/                  # Package installation
│   ├── core/                    # Core installation (always needed)
│   │   ├── paru-install.sh
│   │   ├── base-tools.sh
│   │   ├── desktop-packages.sh
│   │   └── aur-packages.sh
│   └── optional/                # Optional tools
│       ├── atuin-install.sh
│       ├── starship-install.sh
│       ├── homebrew-install.sh
│       ├── signal-install.sh
│       └── ...
│
├── postinstall/                  # Post-installation config
│   ├── dotfile-symlinks.sh
│   ├── nas-mount.sh
│   └── nas-symlinks.sh
│
├── desktop/                      # Desktop Environment configs
│   ├── gnome/
│   │   ├── get-shortcuts.sh
│   │   └── restore-shortcuts.sh
│   └── kde/
│       ├── shortcuts-export.sh
│       └── wallet-setup.sh
│
├── hardware/                     # Hardware-specific scripts
│   ├── openrgb-udev-install.sh  # ← VERSCHIEBEN von root
│   ├── amd-vulkan-setup.sh      # ← VERSCHIEBEN von fixes/
│   └── rpi-hdmi-fix.sh          # ← VERSCHIEBEN von fixes/
│
├── fixes/                        # Software/Network fixes
│   ├── apparmor-optimize.sh
│   └── tailscale-dns-fix.sh
│
├── system-setup/                 # System configuration (safe)
│   ├── locale-setup.sh
│   ├── yubikey-pam-setup.sh     # ← VERSCHIEBEN von root (yk-pam.sh)
│   └── systemd/                 # Systemd services & units
│       ├── inprem-unit.sh       # ← VERSCHIEBEN & UMBENENNEN
│       ├── protonvpn-unit.sh    # ← VERSCHIEBEN & UMBENENNEN (pvpn)
│       └── nas-mount.service
│
├── advanced/                     # ⚠️ UNSAFE/UNTESTED scripts
│   └── apparmor-grub-setup.sh   # ← VERSCHIEBEN von system-setup/
│
├── distro/                       # Distro-specific scripts
│   ├── blendos/
│   │   └── systemyaml-symlink.sh
│   └── windows/
│       └── kali-wsl-setup.ps1
│
└── examples/                     # Example/demo scripts
    └── os-detection-usage.sh    # ← VERSCHIEBEN (example-os-usage.sh)
```

---

## Konkrete Aktionen

### Umbenennungen:

```bash
# Bessere Benennung
mv yk-pam.sh system-setup/yubikey-pam-setup.sh
mv inprem-sdunit.sh system-setup/systemd/inprem-unit.sh  # oder besser benennen?
mv pvpn-sdunit.sh system-setup/systemd/protonvpn-unit.sh
```

### Verschiebungen:

```bash
# Hardware-Skripte zusammenfassen
mkdir -p hardware/
mv openrgb-udev-install.sh hardware/
mv fixes/amd-vulkan-setup.sh hardware/
mv fixes/rpi-hdmi-fix.sh hardware/

# Libraries separieren
mkdir -p lib/
mv detect-os.sh lib/
mv pretty-output.sh lib/

# Gefährliche Skripte isolieren
mkdir -p advanced/
mv system-setup/apparmor-grub-setup.sh advanced/

# Beispiele separieren
mkdir -p examples/
mv example-os-usage.sh examples/os-detection-usage.sh

# Distro-spezifisch gruppieren
mkdir -p distro/
mv blendos/ distro/
mv windows/ distro/

# Desktop Environment besser gruppieren
mkdir -p desktop/
mv gnome/ desktop/
mv kde/ desktop/
```

---

## Zusammenfassung

### Aktuelle Organisation: **7/10** 👍

**Gut:**

- Logische Kategorien (pkg-scripts, postinstall, fixes)
- DE-spezifische Trennung
- Klare Zweckbindung der Ordner

**Verbesserbar:**

- Zu viele Root-Level Skripte (7 Stück)
- Fehlende Kategorien (lib/, hardware/, advanced/)
- Unklare Benennungen (inprem, pvpn)
- Mix aus sicheren/unsicheren Skripten

### Nach Umstrukturierung: **9/10** 🎯

Mit den vorgeschlagenen Änderungen:

- ✅ Keine losen Root-Skripte
- ✅ Klare lib/ für Shared Code
- ✅ hardware/ für Hardware-Fixes
- ✅ advanced/ für gefährliche Skripte
- ✅ Bessere Benennung
- ✅ Logische Gruppierung auf allen Ebenen

#### Specific Tools (können später/optional):

- `fastfetch-install.sh` - System Info Tool
- `atuin-install.sh` - Shell History
- `tailscale-install.sh` - VPN
- `starship-install.sh` - Shell Prompt
- `homebrew-install.sh` - Homebrew Package Manager
- `signal-install.sh` - Messenger
- `blackarch.sh` - Security Tools Repository
- `strap.sh` - macOS-Style Tool (?)

#### Post-Package Steps:

- `podman-postinstall.sh` - Podman Socket Activation
- `flatpak-restore.sh` / `flatpak-backup.sh` - Flatpak Management
- `arch-get-installed.sh` - Paketliste Export

**Optimierungsvorschlag:**

```
Reihenfolge sollte sein:
1. paru-install.sh (AUR helper first!)
2. base-tools.sh (core CLI tools)
3. desktop-packages.sh (GUI apps)
4. aur-packages.sh (with CLI/GUI dialog)
5. Specific tools (atuin, starship, etc.)
6. Post-install (podman, flatpak)
```

---

### **postinstall/** - Konfiguration nach Installation

**Zweck:** Dotfiles und Symlinks einrichten

- `dotfile-symlinks.sh` - Config-Dateien verlinken
- `nas-mount.sh` - NAS via SSHFS mounten (NEU, gut!)
- `nas-symlinks.sh` - Symlinks zu NAS-Shares

**Logik:** Erst Pakete, dann Configs verlinken ✅

---

### **fixes/** - System-Fixes und Patches

**Zweck:** Spezifische Hardware/Software-Probleme beheben

- `amd-vulkan-setup.sh` - AMD GPU Vulkan Config
- `apparmor-optimize.sh` - AppArmor Performance
- `rpi-hdmi-fix.sh` - Raspberry Pi HDMI
- `tailscale-dns-fix.sh` - Tailscale DNS Issues

**Logik:** Sollten NACH base installation laufen, optional

---

### **system-setup/** - Systemweite Konfiguration

**Zweck:** Tiefe System-Änderungen (Bootloader, Locale, etc.)

- `apparmor-grub-setup.sh` - ⚠️ UNTESTED! GRUB Boot Parameter
- `locale-setup.sh` - Locale/Language Setup
- `nas-mount.service` - Systemd Service für NAS

**PROBLEM:**

- `apparmor-grub-setup.sh` ist als gefährlich markiert
- Sollte vielleicht zu `fixes/` oder eigener `advanced/` Ordner?

---

### **gnome/** & **kde/** - Desktop Environment Specific

**Zweck:** DE-spezifische Configs

**GNOME:**

- `get-gnome-shortcuts.sh` - Shortcuts exportieren
- `restore-gnome-shortcuts.sh` - Shortcuts wiederherstellen

**KDE:**

- `kde-shortcuts-export.sh` - Shortcuts exportieren
- `kdewallet-setup.sh` - KDE Wallet

**Logik:** Conditional - nur für das aktive DE

---

### **Root-Level Scripts** - Utilities

- `detect-os.sh` - OS/Distro Detection (wichtig, wird von install.sh genutzt)
- `pretty-output.sh` - Farben und Formatierung
- `yk-pam.sh` - YubiKey PAM Setup
- `openrgb-udev-install.sh` - OpenRGB Hardware Access
- `inprem-sdunit.sh` / `pvpn-sdunit.sh` - Systemd Units (?)
- `example-os-usage.sh` - Beispiel für OS-Detection

---

## Probleme & Inkonsistenzen

### 1. **Falsche Kategorisierung**

- `openrgb-udev-install.sh` ist im root, sollte zu `system-setup/` oder `fixes/`
- `yk-pam.sh` ist im root, sollte zu `system-setup/` (da system-wide PAM)
- `nas-mount.sh` ist in `postinstall/`, könnte auch zu `system-setup/` (da systemd service)

### 2. **Fehlende im install.sh**

- `aur-packages.sh` wird NICHT im install.sh aufgerufen!
- `nas-mount.sh` wird NICHT aufgerufen (nur nas-symlinks.sh)
- Viele `fixes/` Skripte werden nicht aufgerufen

### 3. **Installationsreihenfolge**

Im install.sh fehlt:

```bash
ask_run_step "Install paru AUR helper" "${ROOT_DIR}/scripts/pkg-scripts/paru-install.sh"
# ^ Sollte VOR base-tools.sh laufen!

ask_run_step "Install AUR packages" "${ROOT_DIR}/scripts/pkg-scripts/aur-packages.sh"
# ^ Fehlt komplett!
```

### 4. **System-Setup Scripts**

Gefährliche Skripte wie `apparmor-grub-setup.sh` sollten:

- In separaten "Advanced Setup" Schritt
- Mit extra Warnung
- Oder ganz außerhalb von install.sh

---

## Empfohlene Struktur-Verbesserungen

### A) **Neue Ordnerstruktur**

```
scripts/
├── core/              # OS detection, pretty output (utilities)
├── pkg-install/       # Alles zur Paketinstallation
│   ├── 01-aur-helper.sh
│   ├── 02-base-tools.sh
│   ├── 03-desktop-packages.sh
│   ├── 04-aur-packages.sh
│   └── optional/      # atuin, starship, homebrew, etc.
├── postinstall/       # Configs nach Installation
├── desktop/           # DE-specific (gnome/, kde/)
├── hardware/          # Hardware-specific (openrgb, amd-vulkan, rpi-fix)
├── system/            # System-level (locale, apparmor, nas-mount.service)
├── advanced/          # UNSAFE/UNTESTED scripts (GRUB, etc.)
└── distro-specific/   # blendos/, windows/
```

### B) **install.sh Reihenfolge optimieren**

```bash
# 1. Prerequisites
ask_run_step "Install paru" paru-install.sh

# 2. Packages
ask_run_step "Base tools" base-tools.sh
ask_run_step "Desktop packages" desktop-packages.sh
ask_run_step "AUR packages" aur-packages.sh  # <-- FEHLT!

# 3. Optional Tools
ask_run_step "Atuin" atuin-install.sh
ask_run_step "Starship" starship-install.sh
# etc.

# 4. Post-install
ask_run_step "Symlink configs" dotfile-symlinks.sh
ask_run_step "Mount NAS" nas-mount.sh  # <-- FEHLT!
ask_run_step "NAS symlinks" nas-symlinks.sh

# 5. DE-specific (conditional)
# 6. Security (YubiKey)
# 7. Optional: Hardware fixes
# 8. Optional: Advanced/dangerous
```

### C) **Skripte umbenennen/verschieben**

```
openrgb-udev-install.sh → hardware/openrgb-udev-install.sh
yk-pam.sh → system/yubikey-pam-setup.sh
apparmor-grub-setup.sh → advanced/apparmor-grub-setup.sh (UNSAFE!)
inprem-sdunit.sh → system/systemd/inprem-unit.sh
pvpn-sdunit.sh → system/systemd/pvpn-unit.sh
```

---

## Zusammenfassung

### Gut:

✅ Modularer Aufbau mit interaktivem Dialog
✅ OS-Detection vorhanden
✅ Klare Trennung pkg-scripts vs postinstall
✅ DE-specific Ordner (gnome/kde)
✅ Fixes-Ordner für spezifische Probleme

### Verbesserungsbedarf:

❌ `aur-packages.sh` nicht in install.sh integriert
❌ `paru-install.sh` sollte VOR base-tools.sh
❌ `nas-mount.sh` nicht aufgerufen
❌ Viele Scripts im root-level statt kategorisiert
❌ system-setup/ enthält gefährliche/ungetestete Skripte
❌ Keine klare Trennung safe/unsafe scripts

### Priorität:

1. **install.sh updaten** - paru-install.sh, aur-packages.sh, nas-mount.sh hinzufügen
2. **Reihenfolge fixen** - paru ZUERST
3. **Scripts verschieben** - openrgb, yk-pam in passende Ordner
4. **Advanced-Ordner** - für gefährliche Skripte wie apparmor-grub
