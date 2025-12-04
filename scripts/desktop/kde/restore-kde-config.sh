#!/usr/bin/env bash
#
# KDE Plasma Desktop Configuration Restore Script
# Stellt KDE-Einstellungen, Akonadi-Configs und Themes wieder her
#

set -euo pipefail

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktion zur Anzeige der Verwendung
usage() {
    echo -e "${BLUE}Verwendung:${NC}"
    echo -e "  $0 <backup-verzeichnis>"
    echo -e "  $0 <backup-archiv.tar.gz>"
    echo -e "\n${YELLOW}Beispiel:${NC}"
    echo -e "  $0 ~/kde-backup-20241204-153000"
    echo -e "  $0 ~/kde-backup-20241204-153000.tar.gz"
    exit 1
}

# Prüfe Parameter
if [ $# -eq 0 ]; then
    echo -e "${RED}Fehler: Kein Backup-Verzeichnis angegeben${NC}\n"
    usage
fi

BACKUP_SOURCE="$1"
TEMP_DIR=""

# Prüfe ob es ein Archiv ist
if [[ "$BACKUP_SOURCE" == *.tar.gz ]]; then
    if [ ! -f "$BACKUP_SOURCE" ]; then
        echo -e "${RED}Fehler: Archiv nicht gefunden: $BACKUP_SOURCE${NC}"
        exit 1
    fi
    echo -e "${BLUE}Entpacke Archiv...${NC}"
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$BACKUP_SOURCE" -C "$TEMP_DIR"
    BACKUP_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "kde-backup-*" | head -n 1)
    if [ -z "$BACKUP_DIR" ]; then
        echo -e "${RED}Fehler: Kein gültiges Backup im Archiv gefunden${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    BACKUP_DIR="$BACKUP_SOURCE"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}Fehler: Backup-Verzeichnis nicht gefunden: $BACKUP_DIR${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}=== KDE Plasma Configuration Restore ===${NC}"
echo -e "${GREEN}Backup-Quelle: ${BACKUP_DIR}${NC}\n"

# Zeige Backup-Info falls vorhanden
if [ -f "$BACKUP_DIR/backup-info.txt" ]; then
    echo -e "${YELLOW}=== Backup-Informationen ===${NC}"
    cat "$BACKUP_DIR/backup-info.txt"
    echo -e "${YELLOW}==============================${NC}\n"
fi

# Sicherheitsabfrage
echo -e "${YELLOW}⚠ WARNUNG: Diese Operation überschreibt deine aktuellen KDE-Einstellungen!${NC}"
echo -e "${YELLOW}Möchtest du fortfahren? (j/n)${NC}"
read -r -n 1 confirm
echo
if [[ ! "$confirm" =~ ^[jJyY]$ ]]; then
    echo -e "${RED}Abgebrochen.${NC}"
    [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    exit 0
fi

# Backup der aktuellen Konfiguration erstellen
echo -e "\n${BLUE}Erstelle Sicherungskopie der aktuellen Konfiguration...${NC}"
CURRENT_BACKUP="${HOME}/kde-config-before-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CURRENT_BACKUP"
[ -d "$HOME/.config" ] && cp -r "$HOME/.config" "$CURRENT_BACKUP/" 2>/dev/null || true
echo -e "${GREEN}✓ Aktuelle Config gesichert in: ${CURRENT_BACKUP}${NC}"

# Funktion zum Wiederherstellen
restore_item() {
    local source="$1"
    local dest="$2"
    local description="$3"
    
    if [ -e "$source" ]; then
        echo -e "${YELLOW}➜${NC} Stelle wieder her: $description"
        mkdir -p "$(dirname "$dest")"
        
        # Lösche Ziel falls vorhanden
        if [ -e "$dest" ]; then
            rm -rf "$dest"
        fi
        
        cp -r "$source" "$dest" 2>/dev/null || {
            echo -e "${RED}  ✗ Fehler beim Wiederherstellen${NC}"
            return 1
        }
        echo -e "${GREEN}  ✓ Erfolgreich${NC}"
    else
        echo -e "${YELLOW}  ⊗ Überspringe (nicht im Backup): $description${NC}"
    fi
}

# Stoppe KDE Plasma und Akonadi Services
echo -e "\n${BLUE}Stoppe KDE Plasma und Akonadi...${NC}"
akonadictl stop 2>/dev/null || echo -e "${YELLOW}  Akonadi war nicht aktiv${NC}"
kquitapp5 plasmashell 2>/dev/null || echo -e "${YELLOW}  Plasmashell war nicht aktiv${NC}"
sleep 2

# === Wiederherstellen der Konfigurationsdateien ===
echo -e "\n${BLUE}[1/7] Stelle Plasma Konfigurationsdateien wieder her${NC}"
if [ -d "$BACKUP_DIR/config" ]; then
    for config_file in "$BACKUP_DIR/config"/*; do
        if [ -f "$config_file" ]; then
            filename=$(basename "$config_file")
            restore_item "$config_file" "$HOME/.config/$filename" "$filename"
        fi
    done
fi

# === Akonadi Konfigurationen ===
echo -e "\n${BLUE}[2/7] Stelle Akonadi Konfigurationen wieder her${NC}"
restore_item "$BACKUP_DIR/config/akonadi" "$HOME/.config/akonadi" "Akonadi Hauptverzeichnis"
restore_item "$BACKUP_DIR/local/share/akonadi" "$HOME/.local/share/akonadi" "Akonadi Datenverzeichnis"

# === Themes und Erscheinungsbild ===
echo -e "\n${BLUE}[3/7] Stelle Themes und Erscheinungsbild wieder her${NC}"
restore_item "$BACKUP_DIR/local/share/plasma" "$HOME/.local/share/plasma" "Plasma Themes & Layouts"
restore_item "$BACKUP_DIR/local/share/color-schemes" "$HOME/.local/share/color-schemes" "Farbschemata"
restore_item "$BACKUP_DIR/local/share/aurorae" "$HOME/.local/share/aurorae" "Aurorae Window Decorations"
restore_item "$BACKUP_DIR/local/share/icons" "$HOME/.local/share/icons" "Icon Themes"
restore_item "$BACKUP_DIR/icons" "$HOME/.icons" "Icon Themes (alt)"
restore_item "$BACKUP_DIR/config/gtk-3.0" "$HOME/.config/gtk-3.0" "GTK3 Konfiguration"
restore_item "$BACKUP_DIR/config/gtk-4.0" "$HOME/.config/gtk-4.0" "GTK4 Konfiguration"
restore_item "$BACKUP_DIR/gtkrc-2.0" "$HOME/.gtkrc-2.0" "GTK2 Konfiguration"
restore_item "$BACKUP_DIR/local/share/konsole" "$HOME/.local/share/konsole" "Konsole Profile & Themes"

# === Wallpapers ===
echo -e "\n${BLUE}[4/7] Stelle Wallpapers wieder her${NC}"
restore_item "$BACKUP_DIR/local/share/wallpapers" "$HOME/.local/share/wallpapers" "Wallpapers"

# === Widgets und Plasmoids ===
echo -e "\n${BLUE}[5/7] Stelle Widgets und Plasmoids wieder her${NC}"
restore_item "$BACKUP_DIR/local/share/plasmoids" "$HOME/.local/share/plasmoids" "Plasmoids"
restore_item "$BACKUP_DIR/local/share/plasma_icons" "$HOME/.local/share/plasma_icons" "Plasma Icons"

# === KWin Scripts ===
echo -e "\n${BLUE}[6/7] Stelle KWin Scripts und Effekte wieder her${NC}"
restore_item "$BACKUP_DIR/local/share/kwin" "$HOME/.local/share/kwin" "KWin Scripts & Effekte"

# === KDE Apps ===
echo -e "\n${BLUE}[7/7] Stelle KDE App-Einstellungen wieder her${NC}"
restore_item "$BACKUP_DIR/local/share/dolphin" "$HOME/.local/share/dolphin" "Dolphin Einstellungen"
restore_item "$BACKUP_DIR/local/share/kxmlgui5" "$HOME/.local/share/kxmlgui5" "KDE XML GUI Layouts"

# === Akonadi neu starten ===
echo -e "\n${BLUE}Starte Akonadi...${NC}"
akonadictl start 2>/dev/null || echo -e "${YELLOW}  Warnung: Akonadi konnte nicht gestartet werden${NC}"
sleep 3

# === Plasma Shell neu starten ===
echo -e "\n${BLUE}Starte Plasma Shell...${NC}"
kstart5 plasmashell 2>/dev/null &
sleep 2

# Cache aktualisieren
echo -e "\n${BLUE}Aktualisiere KDE Caches...${NC}"
kbuildsycoca5 --noincremental 2>/dev/null || echo -e "${YELLOW}  Warnung: Cache-Update fehlgeschlagen${NC}"

# Aufräumen
if [ -n "$TEMP_DIR" ]; then
    echo -e "\n${BLUE}Räume temporäre Dateien auf...${NC}"
    rm -rf "$TEMP_DIR"
fi

echo -e "\n${GREEN}=== Wiederherstellung abgeschlossen! ===${NC}"
echo -e "${YELLOW}Hinweise:${NC}"
echo -e "  • Melde dich ab und wieder an, um alle Änderungen zu übernehmen"
echo -e "  • Bei Problemen findest du deine alte Config in: ${CURRENT_BACKUP}"
echo -e "  • Akonadi benötigt ggf. einige Minuten zur Synchronisation"
echo -e "\n${BLUE}Möchtest du dich jetzt abmelden? (j/n)${NC}"
read -r -n 1 logout_choice
echo
if [[ "$logout_choice" =~ ^[jJyY]$ ]]; then
    qdbus org.kde.ksmserver /KSMServer logout 0 0 0
fi
