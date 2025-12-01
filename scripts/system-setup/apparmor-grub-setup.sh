#!/usr/bin/env bash

# ⚠️  WARNING: UNTESTED AND POTENTIALLY UNSAFE ⚠️
# This script modifies GRUB boot parameters and may cause boot failures
# DO NOT RUN without full backup and recovery plan
#
# AppArmor Boot Parameter Setup
# SAFELY adds AppArmor to GRUB boot parameters
# Includes validation and backup mechanisms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# WARNING: Get explicit confirmation
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}⚠️  WARNING: UNTESTED SCRIPT - MAY CAUSE BOOT FAILURE ⚠️${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}This script will modify GRUB boot parameters.${NC}"
echo -e "${YELLOW}If something goes wrong, your system may not boot.${NC}"
echo ""
echo -e "${YELLOW}Before continuing, ensure you have:${NC}"
echo "  1. Full system backup"
echo "  2. Live USB/recovery media available"
echo "  3. Knowledge to restore from backup"
echo ""
read -p "Type 'I UNDERSTAND THE RISKS' to continue: " confirmation

if [ "$confirmation" != "I UNDERSTAND THE RISKS" ]; then
    echo -e "${RED}Aborted by user${NC}"
    exit 1
fi
echo ""

GRUB_CONFIG="/etc/default/grub"

# Check if GRUB config exists
if [ ! -f "$GRUB_CONFIG" ]; then
    echo -e "${RED}Error: $GRUB_CONFIG not found. Is GRUB installed?${NC}"
    exit 1
fi

# Backup the original GRUB config
BACKUP_FILE="${GRUB_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}Creating backup: ${BACKUP_FILE}${NC}"
cp "$GRUB_CONFIG" "$BACKUP_FILE"

# Check if AppArmor is already in boot parameters
if grep -q 'apparmor=1' "$GRUB_CONFIG" && grep -q 'security=apparmor' "$GRUB_CONFIG"; then
    echo -e "${YELLOW}AppArmor boot parameters already configured${NC}"
    exit 0
fi

echo -e "${GREEN}Adding AppArmor to boot parameters...${NC}"

# Get current GRUB_CMDLINE_LINUX_DEFAULT value
CURRENT_CMDLINE=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_CONFIG" | cut -d'"' -f2)

# Check if we need to add AppArmor parameters
NEEDS_UPDATE=false
NEW_CMDLINE="$CURRENT_CMDLINE"

if [[ ! "$CURRENT_CMDLINE" =~ apparmor=1 ]]; then
    NEW_CMDLINE="$NEW_CMDLINE apparmor=1"
    NEEDS_UPDATE=true
fi

if [[ ! "$CURRENT_CMDLINE" =~ security=apparmor ]]; then
    NEW_CMDLINE="$NEW_CMDLINE security=apparmor"
    NEEDS_UPDATE=true
fi

if [ "$NEEDS_UPDATE" = false ]; then
    echo -e "${YELLOW}AppArmor parameters already present${NC}"
    exit 0
fi

# Trim leading/trailing spaces
NEW_CMDLINE=$(echo "$NEW_CMDLINE" | xargs)

echo -e "${YELLOW}Current boot parameters:${NC} $CURRENT_CMDLINE"
echo -e "${YELLOW}New boot parameters:${NC} $NEW_CMDLINE"

# Update the GRUB config
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW_CMDLINE\"|" "$GRUB_CONFIG"

echo -e "${GREEN}✓ GRUB config updated${NC}"

# Verify the change
if ! grep -q 'apparmor=1' "$GRUB_CONFIG" || ! grep -q 'security=apparmor' "$GRUB_CONFIG"; then
    echo -e "${RED}ERROR: Failed to update GRUB config properly${NC}"
    echo -e "${YELLOW}Restoring backup...${NC}"
    cp "$BACKUP_FILE" "$GRUB_CONFIG"
    echo -e "${GREEN}✓ Backup restored${NC}"
    exit 1
fi

# Update GRUB
echo -e "${YELLOW}Updating GRUB bootloader...${NC}"

if command -v grub-mkconfig &> /dev/null; then
    grub-mkconfig -o /boot/grub/grub.cfg
elif command -v update-grub &> /dev/null; then
    update-grub
else
    echo -e "${RED}ERROR: Neither grub-mkconfig nor update-grub found${NC}"
    echo -e "${YELLOW}Restoring backup...${NC}"
    cp "$BACKUP_FILE" "$GRUB_CONFIG"
    echo -e "${GREEN}✓ Backup restored${NC}"
    exit 1
fi

echo -e "${GREEN}✓ GRUB updated successfully${NC}"
echo ""
echo -e "${YELLOW}AppArmor boot parameters added:${NC}"
echo "  - apparmor=1"
echo "  - security=apparmor"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Reboot required for changes to take effect${NC}"
echo -e "${YELLOW}⚠️  Backup saved at: ${BACKUP_FILE}${NC}"
echo ""
echo -e "${GREEN}If you encounter boot issues:${NC}"
echo "1. Boot into recovery mode or live USB"
echo "2. Mount your root partition"
echo "3. Restore backup: cp ${BACKUP_FILE} ${GRUB_CONFIG}"
echo "4. Regenerate GRUB: grub-mkconfig -o /boot/grub/grub.cfg"
