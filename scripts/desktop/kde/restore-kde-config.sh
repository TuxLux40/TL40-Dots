#!/usr/bin/env bash
#
# KDE Plasma Desktop Configuration Restore Script
# Restores KDE settings, Akonadi configs, and themes
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage helper
usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 <backup-directory>"
    echo -e "  $0 <backup-archive.tar.gz>"
    echo -e "\n${YELLOW}Example:${NC}"
    echo -e "  $0 ~/kde-backup-20241204-153000"
    echo -e "  $0 ~/kde-backup-20241204-153000.tar.gz"
    exit 1
}

# Validate parameters
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No backup directory provided${NC}\n"
    usage
fi

BACKUP_SOURCE="$1"
TEMP_DIR=""

# Detect archive input
if [[ "$BACKUP_SOURCE" == *.tar.gz ]]; then
    if [ ! -f "$BACKUP_SOURCE" ]; then
        echo -e "${RED}Error: Archive not found: $BACKUP_SOURCE${NC}"
        exit 1
    fi
    echo -e "${BLUE}Extracting archive...${NC}"
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$BACKUP_SOURCE" -C "$TEMP_DIR"
    BACKUP_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "kde-backup-*" | head -n 1)
    if [ -z "$BACKUP_DIR" ]; then
        echo -e "${RED}Error: No valid backup found in archive${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    BACKUP_DIR="$BACKUP_SOURCE"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}Error: Backup directory not found: $BACKUP_DIR${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}=== KDE Plasma Configuration Restore ===${NC}"
echo -e "${GREEN}Backup source: ${BACKUP_DIR}${NC}\n"

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
    [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    exit 0
fi

# Backup current configuration
echo -e "\n${BLUE}Creating backup of current configuration...${NC}"
CURRENT_BACKUP="${HOME}/kde-config-before-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CURRENT_BACKUP"
[ -d "$HOME/.config" ] && cp -r "$HOME/.config" "$CURRENT_BACKUP/" 2>/dev/null || true
echo -e "${GREEN}✓ Current config saved to: ${CURRENT_BACKUP}${NC}"

# Restore helper
restore_item() {
    local source="$1"
    local dest="$2"
    local description="$3"
    
    if [ -e "$source" ]; then
        echo -e "${YELLOW}➜${NC} Restoring: $description"
        mkdir -p "$(dirname "$dest")"
        
        # Delete target if it exists
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

# === Restore configuration files ===
echo -e "\n${BLUE}[1/7] Restoring Plasma configuration files${NC}"
if [ -d "$BACKUP_DIR/config" ]; then
    for config_file in "$BACKUP_DIR/config"/*; do
        if [ -f "$config_file" ]; then
            filename=$(basename "$config_file")
            restore_item "$config_file" "$HOME/.config/$filename" "$filename"
        fi
    done
fi

# === Akonadi configurations ===
echo -e "\n${BLUE}[2/7] Restoring Akonadi configurations${NC}"
restore_item "$BACKUP_DIR/config/akonadi" "$HOME/.config/akonadi" "Akonadi main directory"
restore_item "$BACKUP_DIR/local/share/akonadi" "$HOME/.local/share/akonadi" "Akonadi data directory"

# === Themes and appearance ===
echo -e "\n${BLUE}[3/7] Restoring themes and appearance${NC}"
restore_item "$BACKUP_DIR/local/share/plasma" "$HOME/.local/share/plasma" "Plasma Themes & Layouts"
restore_item "$BACKUP_DIR/local/share/color-schemes" "$HOME/.local/share/color-schemes" "Color schemes"
restore_item "$BACKUP_DIR/local/share/aurorae" "$HOME/.local/share/aurorae" "Aurorae Window Decorations"
restore_item "$BACKUP_DIR/local/share/icons" "$HOME/.local/share/icons" "Icon Themes"
restore_item "$BACKUP_DIR/icons" "$HOME/.icons" "Icon Themes (alt)"
restore_item "$BACKUP_DIR/config/gtk-3.0" "$HOME/.config/gtk-3.0" "GTK3 configuration"
restore_item "$BACKUP_DIR/config/gtk-4.0" "$HOME/.config/gtk-4.0" "GTK4 configuration"
restore_item "$BACKUP_DIR/gtkrc-2.0" "$HOME/.gtkrc-2.0" "GTK2 configuration"
restore_item "$BACKUP_DIR/local/share/konsole" "$HOME/.local/share/konsole" "Konsole profiles & themes"

# === Wallpapers ===
echo -e "\n${BLUE}[4/7] Restoring wallpapers${NC}"
restore_item "$BACKUP_DIR/local/share/wallpapers" "$HOME/.local/share/wallpapers" "Wallpapers"

# === Widgets and Plasmoids ===
echo -e "\n${BLUE}[5/7] Restoring widgets and plasmoids${NC}"
restore_item "$BACKUP_DIR/local/share/plasmoids" "$HOME/.local/share/plasmoids" "Plasmoids"
restore_item "$BACKUP_DIR/local/share/plasma_icons" "$HOME/.local/share/plasma_icons" "Plasma Icons"

# === KWin scripts ===
echo -e "\n${BLUE}[6/7] Restoring KWin scripts and effects${NC}"
restore_item "$BACKUP_DIR/local/share/kwin" "$HOME/.local/share/kwin" "KWin Scripts & Effects"

# === KDE apps ===
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

# Cleanup
if [ -n "$TEMP_DIR" ]; then
    echo -e "\n${BLUE}Cleaning up temporary files...${NC}"
    rm -rf "$TEMP_DIR"
fi

echo -e "\n${GREEN}=== Restore completed! ===${NC}"
echo -e "${YELLOW}Notes:${NC}"
echo -e "  • Log out and back in to apply all changes"
echo -e "  • If you have issues, your old config is at: ${CURRENT_BACKUP}"
echo -e "  • Akonadi may need a few minutes to sync"
echo -e "\n${BLUE}Do you want to log out now? (y/n)${NC}"
read -r -n 1 logout_choice
echo
if [[ "$logout_choice" =~ ^[jJyY]$ ]]; then
    qdbus org.kde.ksmserver /KSMServer logout 0 0 0
fi
