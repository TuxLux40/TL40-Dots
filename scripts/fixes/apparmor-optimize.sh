#!/usr/bin/env bash

# AppArmor Parser Configuration Script
# Adds performance optimizations to /etc/apparmor/parser.conf

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

PARSER_CONF="/etc/apparmor/parser.conf"

# Check if AppArmor is installed
if [ ! -f "$PARSER_CONF" ]; then
    echo -e "${RED}Error: $PARSER_CONF not found. Is AppArmor installed?${NC}"
    exit 1
fi

# Backup the original file
BACKUP_FILE="${PARSER_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}Creating backup: ${BACKUP_FILE}${NC}"
cp "$PARSER_CONF" "$BACKUP_FILE"

# Define the configuration to add
APPARMOR_CONFIG="
## Performance optimizations
write-cache
Optimize=compress-fast"

# Check if configuration already exists
if grep -q "^write-cache" "$PARSER_CONF" && grep -q "^Optimize=compress-fast" "$PARSER_CONF"; then
    echo -e "${YELLOW}AppArmor optimizations already exist in $PARSER_CONF${NC}"
    echo -e "${YELLOW}Skipping to avoid duplicates${NC}"
    exit 0
fi

# Add configuration to parser.conf
echo -e "${GREEN}Adding AppArmor optimizations to $PARSER_CONF...${NC}"
echo "$APPARMOR_CONFIG" >> "$PARSER_CONF"

echo -e "${GREEN}✓ Configuration added successfully!${NC}"
echo -e "${YELLOW}Reloading AppArmor profiles to apply changes...${NC}"

# Reload AppArmor
if systemctl is-active --quiet apparmor; then
    systemctl reload apparmor
    echo -e "${GREEN}✓ AppArmor reloaded${NC}"
else
    echo -e "${YELLOW}Note: AppArmor service is not running. Start it with: systemctl start apparmor${NC}"
fi

echo ""
echo "Added configuration:"
echo "$APPARMOR_CONFIG"
