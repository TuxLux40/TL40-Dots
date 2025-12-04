#!/usr/bin/env bash
#
# KDE Plasma Desktop Configuration Backup Script
# Backs up all important KDE settings, Akonadi configs and themes
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Backup directory with timestamp
BACKUP_DIR="${HOME}/kde-backup-$(date +%Y%m%d-%H%M%S)"
RESTORE_SCRIPT="$(dirname "$0")/restore-kde-config.sh"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}=== KDE Plasma Configuration Backup ===${NC}"
echo -e "${GREEN}Backup directory: ${BACKUP_DIR}${NC}"
echo -e "${GREEN}Restore script: ${RESTORE_SCRIPT}${NC}\n"

# Function to copy items with status output
backup_item() {
    local source="$1"
    local dest="$2"
    local description="$3"
    
    if [ -e "$source" ]; then
        echo -e "${YELLOW}➜${NC} Backing up: $description"
        mkdir -p "$(dirname "$dest")"
        cp -r "$source" "$dest" 2>/dev/null || echo -e "${RED}  ✗ Error copying${NC}"
        echo -e "${GREEN}  ✓ Success${NC}"
    else
        echo -e "${YELLOW}  ⊗ Skipping (not found): $description${NC}"
    fi
}

# === KDE Plasma Configuration Files ===
echo -e "\n${BLUE}[1/7] Plasma Configuration Files${NC}"
CONFIG_FILES=(
    "plasma-org.kde.plasma.desktop-appletsrc"
    "plasmashellrc"
    "plasmarc"
    "kwinrc"
    "kglobalshortcutsrc"
    "kdeglobals"
    "kscreenlockerrc"
    "ksmserverrc"
    "ksplashrc"
    "krunnerrc"
    "kactivitymanagerdrc"
    "baloofilerc"
    "kded5rc"
)

for config in "${CONFIG_FILES[@]}"; do
    backup_item "$HOME/.config/$config" "$BACKUP_DIR/config/$config" "$config"
done

# === Akonadi Configurations ===
echo -e "\n${BLUE}[2/7] Akonadi Configurations${NC}"
AKONADI_FILES=(
    "akonadi/akonadiserverrc"
    "akonadi_*rc"
    "akonadi-firstrunrc"
)

backup_item "$HOME/.config/akonadi" "$BACKUP_DIR/config/akonadi" "Akonadi main directory"
backup_item "$HOME/.local/share/akonadi" "$BACKUP_DIR/local/share/akonadi" "Akonadi data directory"

for pattern in "${AKONADI_FILES[@]}"; do
    for file in $HOME/.config/$pattern; do
        if [ -e "$file" ]; then
            filename=$(basename "$file")
            backup_item "$file" "$BACKUP_DIR/config/$filename" "$filename"
        fi
    done
done

# === KDE Themes and Appearance ===
echo -e "\n${BLUE}[3/7] Themes and Appearance${NC}"

# Plasma Themes
backup_item "$HOME/.local/share/plasma" "$BACKUP_DIR/local/share/plasma" "Plasma Themes & Layouts"
backup_item "$HOME/.local/share/color-schemes" "$BACKUP_DIR/local/share/color-schemes" "Color schemes"
backup_item "$HOME/.local/share/aurorae" "$BACKUP_DIR/local/share/aurorae" "Aurorae Window Decorations"

# Icons and Cursor Themes
backup_item "$HOME/.local/share/icons" "$BACKUP_DIR/local/share/icons" "Icon Themes"
backup_item "$HOME/.icons" "$BACKUP_DIR/icons" "Icon Themes (alt)"

# GTK Themes
backup_item "$HOME/.config/gtk-3.0" "$BACKUP_DIR/config/gtk-3.0" "GTK3 configuration"
backup_item "$HOME/.config/gtk-4.0" "$BACKUP_DIR/config/gtk-4.0" "GTK4 configuration"
backup_item "$HOME/.gtkrc-2.0" "$BACKUP_DIR/gtkrc-2.0" "GTK2 configuration"

# Konsole Themes
backup_item "$HOME/.local/share/konsole" "$BACKUP_DIR/local/share/konsole" "Konsole Profile & Themes"

# === KDE Wallpapers ===
echo -e "\n${BLUE}[4/7] Wallpapers${NC}"
backup_item "$HOME/.local/share/wallpapers" "$BACKUP_DIR/local/share/wallpapers" "Wallpapers"

# === KDE Widgets and Plasmoids ===
echo -e "\n${BLUE}[5/7] Widgets and Plasmoids${NC}"
backup_item "$HOME/.local/share/plasmoids" "$BACKUP_DIR/local/share/plasmoids" "Plasmoids"
backup_item "$HOME/.local/share/plasma_icons" "$BACKUP_DIR/local/share/plasma_icons" "Plasma Icons"

# === KWin Scripts and Effects ===
echo -e "\n${BLUE}[6/7] KWin Scripts and Effects${NC}"
backup_item "$HOME/.local/share/kwin" "$BACKUP_DIR/local/share/kwin" "KWin Scripts & Effects"

# === Dolphin and File Manager ===
echo -e "\n${BLUE}[7/7] Dolphin and other KDE Apps${NC}"
KDE_APP_CONFIGS=(
    "dolphinrc"
    "konquerorrc"
    "katerc"
    "kwriterc"
    "spectaclerc"
    "okularrc"
    "gwenviewrc"
)

for config in "${KDE_APP_CONFIGS[@]}"; do
    backup_item "$HOME/.config/$config" "$BACKUP_DIR/config/$config" "$config"
done

backup_item "$HOME/.local/share/dolphin" "$BACKUP_DIR/local/share/dolphin" "Dolphin settings"
backup_item "$HOME/.local/share/kxmlgui5" "$BACKUP_DIR/local/share/kxmlgui5" "KDE XML GUI Layouts"

# === Create Metadata ===
echo -e "\n${BLUE}Creating metadata...${NC}"
cat > "$BACKUP_DIR/backup-info.txt" <<EOF
KDE Plasma Configuration Backup
================================
Created: $(date '+%Y-%m-%d %H:%M:%S')
Hostname: $(hostname)
User: $USER
KDE Plasma Version: $(plasmashell --version 2>/dev/null || echo "N/A")
KDE Framework Version: $(kf5-config --version 2>/dev/null | grep "KDE Frameworks" || echo "N/A")

Backup path: $BACKUP_DIR
EOF

# === System Info ===
echo -e "\n${BLUE}Collecting system information...${NC}"
{
    echo -e "\n=== Installed KDE Packages ==="
    if command -v pacman &>/dev/null; then
        pacman -Q | grep -E "plasma|kde|akonadi" || echo "No KDE packages found"
    elif command -v dpkg &>/dev/null; then
        dpkg -l | grep -E "plasma|kde|akonadi" || echo "No KDE packages found"
    elif command -v rpm &>/dev/null; then
        rpm -qa | grep -E "plasma|kde|akonadi" || echo "No KDE packages found"
    else
        echo "Package manager not recognized"
    fi
} >> "$BACKUP_DIR/backup-info.txt"

# === Generate Restore Script with Backup Path ===
echo -e "\n${BLUE}Generating restore script...${NC}"
cat > "$RESTORE_SCRIPT" << 'RESTORE_SCRIPT_EOF'
#!/usr/bin/env bash
#
# KDE Plasma Desktop Configuration Restore Script
# Generated by backup-kde-config.sh on $(date '+%Y-%m-%d %H:%M:%S')
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

RESTORE_SCRIPT_EOF

# Write backup path to restore script
echo "BACKUP_DIR=\"$BACKUP_DIR\"" >> "$RESTORE_SCRIPT"

cat >> "$RESTORE_SCRIPT" << 'RESTORE_SCRIPT_EOF'

echo -e "${BLUE}=== KDE Plasma Configuration Restore ===${NC}"
echo -e "${GREEN}Backup source: ${BACKUP_DIR}${NC}\n"

# Check if backup exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: Backup directory not found: $BACKUP_DIR${NC}"
    exit 1
fi

# Show backup info if available
if [ -f "$BACKUP_DIR/backup-info.txt" ]; then
    echo -e "${YELLOW}=== Backup Information ===${NC}"
    cat "$BACKUP_DIR/backup-info.txt"
    echo -e "${YELLOW}==============================${NC}\n"
fi

# Safety confirmation
echo -e "${YELLOW}⚠ WARNING: This operation will overwrite your current KDE settings!${NC}"
echo -e "${YELLOW}Do you want to continue? (y/n)${NC}"
read -r -n 1 confirm
echo
if [[ ! "$confirm" =~ ^[jJyY]$ ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 0
fi

# Create backup of current configuration
echo -e "\n${BLUE}Creating backup of current configuration...${NC}"
CURRENT_BACKUP="${HOME}/kde-config-before-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CURRENT_BACKUP"
[ -d "$HOME/.config" ] && cp -r "$HOME/.config" "$CURRENT_BACKUP/" 2>/dev/null || true
echo -e "${GREEN}✓ Current config backed up to: ${CURRENT_BACKUP}${NC}"

# Function to restore items
restore_item() {
    local source="$1"
    local dest="$2"
    local description="$3"
    
    if [ -e "$source" ]; then
        echo -e "${YELLOW}➜${NC} Restoring: $description"
        mkdir -p "$(dirname "$dest")"
        
        # Delete target if exists
        if [ -e "$dest" ]; then
            rm -rf "$dest"
        fi
        
        cp -r "$source" "$dest" 2>/dev/null || {
            echo -e "${RED}  ✗ Error restoring${NC}"
            return 1
        }
        echo -e "${GREEN}  ✓ Success${NC}"
    else
        echo -e "${YELLOW}  ⊗ Skipping (not in backup): $description${NC}"
    fi
}

# Stop KDE Plasma and Akonadi services
echo -e "\n${BLUE}Stopping KDE Plasma and Akonadi...${NC}"
akonadictl stop 2>/dev/null || echo -e "${YELLOW}  Akonadi was not running${NC}"
kquitapp5 plasmashell 2>/dev/null || echo -e "${YELLOW}  Plasmashell was not running${NC}"
sleep 2

# === Restore Configuration Files ===
echo -e "\n${BLUE}[1/7] Restoring Plasma configuration files${NC}"
if [ -d "$BACKUP_DIR/config" ]; then
    for config_file in "$BACKUP_DIR/config"/*; do
        if [ -f "$config_file" ]; then
            filename=$(basename "$config_file")
            restore_item "$config_file" "$HOME/.config/$filename" "$filename"
        fi
    done
fi

# === Akonadi Configurations ===
echo -e "\n${BLUE}[2/7] Restoring Akonadi configurations${NC}"
restore_item "$BACKUP_DIR/config/akonadi" "$HOME/.config/akonadi" "Akonadi main directory"
restore_item "$BACKUP_DIR/local/share/akonadi" "$HOME/.local/share/akonadi" "Akonadi data directory"

# === Themes and Appearance ===
echo -e "\n${BLUE}[3/7] Restoring themes and appearance${NC}"
restore_item "$BACKUP_DIR/local/share/plasma" "$HOME/.local/share/plasma" "Plasma Themes & Layouts"
restore_item "$BACKUP_DIR/local/share/color-schemes" "$HOME/.local/share/color-schemes" "Color schemes"
restore_item "$BACKUP_DIR/local/share/aurorae" "$HOME/.local/share/aurorae" "Aurorae Window Decorations"
restore_item "$BACKUP_DIR/local/share/icons" "$HOME/.local/share/icons" "Icon Themes"
restore_item "$BACKUP_DIR/icons" "$HOME/.icons" "Icon Themes (alt)"
restore_item "$BACKUP_DIR/config/gtk-3.0" "$HOME/.config/gtk-3.0" "GTK3 configuration"
restore_item "$BACKUP_DIR/config/gtk-4.0" "$HOME/.config/gtk-4.0" "GTK4 configuration"
restore_item "$BACKUP_DIR/gtkrc-2.0" "$HOME/.gtkrc-2.0" "GTK2 configuration"
restore_item "$BACKUP_DIR/local/share/konsole" "$HOME/.local/share/konsole" "Konsole Profile & Themes"

# === Wallpapers ===
echo -e "\n${BLUE}[4/7] Restoring wallpapers${NC}"
restore_item "$BACKUP_DIR/local/share/wallpapers" "$HOME/.local/share/wallpapers" "Wallpapers"

# === Widgets and Plasmoids ===
echo -e "\n${BLUE}[5/7] Restoring widgets and plasmoids${NC}"
restore_item "$BACKUP_DIR/local/share/plasmoids" "$HOME/.local/share/plasmoids" "Plasmoids"
restore_item "$BACKUP_DIR/local/share/plasma_icons" "$HOME/.local/share/plasma_icons" "Plasma Icons"

# === KWin Scripts ===
echo -e "\n${BLUE}[6/7] Restoring KWin scripts and effects${NC}"
restore_item "$BACKUP_DIR/local/share/kwin" "$HOME/.local/share/kwin" "KWin Scripts & Effects"

# === KDE Apps ===
echo -e "\n${BLUE}[7/7] Restoring KDE app settings${NC}"
restore_item "$BACKUP_DIR/local/share/dolphin" "$HOME/.local/share/dolphin" "Dolphin settings"
restore_item "$BACKUP_DIR/local/share/kxmlgui5" "$HOME/.local/share/kxmlgui5" "KDE XML GUI Layouts"

# === Restart Akonadi ===
echo -e "\n${BLUE}Starting Akonadi...${NC}"
akonadictl start 2>/dev/null || echo -e "${YELLOW}  Warning: Could not start Akonadi${NC}"
sleep 3

# === Restart Plasma Shell ===
echo -e "\n${BLUE}Starting Plasma Shell...${NC}"
kstart5 plasmashell 2>/dev/null &
sleep 2

# Update cache
echo -e "\n${BLUE}Updating KDE caches...${NC}"
kbuildsycoca5 --noincremental 2>/dev/null || echo -e "${YELLOW}  Warning: Cache update failed${NC}"

echo -e "\n${GREEN}=== Restore completed! ===${NC}"
echo -e "${YELLOW}Notes:${NC}"
echo -e "  • Log out and back in to apply all changes"
echo -e "  • If you have problems, your old config is in: ${CURRENT_BACKUP}"
echo -e "  • Akonadi may need a few minutes to synchronize"
echo -e "\n${BLUE}Do you want to log out now? (y/n)${NC}"
read -r -n 1 logout_choice
echo
if [[ "$logout_choice" =~ ^[jJyY]$ ]]; then
    qdbus org.kde.ksmserver /KSMServer logout 0 0 0
fi
RESTORE_SCRIPT_EOF

chmod +x "$RESTORE_SCRIPT"
echo -e "${GREEN}✓ Restore script generated${NC}"

echo -e "\n${GREEN}=== Backup completed! ===${NC}"
echo -e "${GREEN}Backup directory: ${BACKUP_DIR}${NC}"
echo -e "${GREEN}Restore script: ${RESTORE_SCRIPT}${NC}"
echo -e "\n${BLUE}To restore, simply run:${NC}"
echo -e "${YELLOW}  ${RESTORE_SCRIPT}${NC}\n"
