#!/bin/bash
# Auto-mount Steam Laufwerke beim Boot
# Damit Steam Big Picture die Laufwerke findet

set -e

# Farben für Output
source "$(dirname "$0")/../lib/pretty-output.sh" 2>/dev/null || {
    info() { echo "[INFO] $*"; }
    success() { echo "[OK] $*"; }
    error() { echo "[ERROR] $*"; }
    warning() { echo "[WARN] $*"; }
}

info "Konfiguriere automatisches Mounten der Steam-Laufwerke..."

# Prüfe ob wir root sind
if [[ $EUID -ne 0 ]]; then
   error "Dieses Script muss als root ausgeführt werden"
   exit 1
fi

# Erstelle Mount-Verzeichnisse
info "Erstelle Mount-Verzeichnisse..."
mkdir -p /mnt/steam-nvme
mkdir -p /mnt/steam-ssd

# Setze Berechtigungen
chown oliver:oliver /mnt/steam-nvme
chown oliver:oliver /mnt/steam-ssd

# Backup der fstab
info "Erstelle Backup der fstab..."
cp /etc/fstab "/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"

# Samsung NVMe UUID
NVME_UUID="65d792f3-2e2c-43dc-84a6-f804331b644a"
# Intel SSD UUID
SSD_UUID="03e21b16-69d4-4870-94e8-94b0997b2a32"

# Prüfe ob Einträge bereits existieren
if grep -q "$NVME_UUID" /etc/fstab; then
    warning "Samsung NVMe Eintrag existiert bereits in fstab"
else
    info "Füge Samsung NVMe zur fstab hinzu..."
    echo "" >> /etc/fstab
    echo "# Steam Games - Samsung NVMe (nvme0n1p1)" >> /etc/fstab
    echo "# Auto-mount beim Boot, damit Steam Big Picture die Games findet" >> /etc/fstab
    echo "UUID=$NVME_UUID /mnt/steam-nvme ext4 defaults,noatime,nofail,x-systemd.device-timeout=5 0 2" >> /etc/fstab
fi

if grep -q "$SSD_UUID" /etc/fstab; then
    warning "Intel SSD Eintrag existiert bereits in fstab"
else
    info "Füge Intel SSD zur fstab hinzu..."
    echo "" >> /etc/fstab
    echo "# Steam Games - Intel SSD (sda1)" >> /etc/fstab
    echo "# Auto-mount beim Boot, damit Steam Big Picture die Games findet" >> /etc/fstab
    echo "UUID=$SSD_UUID /mnt/steam-ssd ext4 defaults,noatime,nofail,x-systemd.device-timeout=5 0 2" >> /etc/fstab
fi

# Test der fstab Konfiguration
info "Teste fstab Konfiguration..."
if mount -a; then
    success "fstab ist korrekt und Laufwerke wurden gemountet!"
else
    error "Fehler beim Mounten. Stelle fstab.backup wieder her!"
    exit 1
fi

# Zeige Mount-Status
echo ""
info "Mount-Status:"
df -h /mnt/steam-nvme /mnt/steam-ssd

echo ""
success "Steam-Laufwerke wurden erfolgreich konfiguriert!"
info "Die Laufwerke werden jetzt automatisch beim Boot unter folgende Pfade gemountet:"
info "  - Samsung NVMe: /mnt/steam-nvme"
info "  - Intel SSD:    /mnt/steam-ssd"
echo ""
info "Nächste Schritte:"
info "1. Füge diese Pfade in Steam als Library-Ordner hinzu"
info "2. Eventuell vorhandene Symlinks oder alte Mount-Points in Steam entfernen"
info "3. Steam neu starten"
