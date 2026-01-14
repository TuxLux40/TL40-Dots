#!/bin/bash
# Auto-mount Steam drives at boot
# So Steam Big Picture can find the drives

set -e

# Colors for output
source "$(dirname "$0")/../lib/pretty-output.sh" 2>/dev/null || {
    info() { echo "[INFO] $*"; }
    success() { echo "[OK] $*"; }
    error() { echo "[ERROR] $*"; }
    warning() { echo "[WARN] $*"; }
}

info "Configuring automatic mounting of Steam drives..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   exit 1
fi

# Create mount directories
info "Creating mount directories..."
mkdir -p /mnt/steam-nvme
mkdir -p /mnt/steam-ssd

# Set permissions
chown oliver:oliver /mnt/steam-nvme
chown oliver:oliver /mnt/steam-ssd

# Backup fstab
info "Creating backup of fstab..."
cp /etc/fstab "/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"

# Samsung NVMe UUID
NVME_UUID="65d792f3-2e2c-43dc-84a6-f804331b644a"
# Intel SSD UUID
SSD_UUID="03e21b16-69d4-4870-94e8-94b0997b2a32"

# Check if entries already exist
if grep -q "$NVME_UUID" /etc/fstab; then
    warning "Samsung NVMe entry already exists in fstab"
else
    info "Adding Samsung NVMe to fstab..."
    echo "" >> /etc/fstab
    echo "# Steam Games - Samsung NVMe (nvme0n1p1)" >> /etc/fstab
    echo "# Auto-mount at boot so Steam Big Picture can find the games" >> /etc/fstab
    echo "UUID=$NVME_UUID /mnt/steam-nvme ext4 defaults,noatime,nofail,x-systemd.device-timeout=5 0 2" >> /etc/fstab
fi

if grep -q "$SSD_UUID" /etc/fstab; then
    warning "Intel SSD entry already exists in fstab"
else
    info "Adding Intel SSD to fstab..."
    echo "" >> /etc/fstab
    echo "# Steam Games - Intel SSD (sda1)" >> /etc/fstab
    echo "# Auto-mount at boot so Steam Big Picture can find the games" >> /etc/fstab
    echo "UUID=$SSD_UUID /mnt/steam-ssd ext4 defaults,noatime,nofail,x-systemd.device-timeout=5 0 2" >> /etc/fstab
fi

# Test fstab configuration
info "Testing fstab configuration..."
if mount -a; then
    success "fstab is correct and drives have been mounted!"
else
    error "Error mounting. Restore fstab.backup!"
    exit 1
fi

# Show mount status
echo ""
info "Mount status:"
df -h /mnt/steam-nvme /mnt/steam-ssd

echo ""
success "Steam drives configured successfully!"
info "The drives will now be mounted automatically at boot to the following paths:"
info "  - Samsung NVMe: /mnt/steam-nvme"
info "  - Intel SSD:    /mnt/steam-ssd"
echo ""
info "Next steps:"
info "1. Add these paths in Steam as library folders"
info "2. Remove any existing symlinks or old mount points in Steam"
info "3. Restart Steam"