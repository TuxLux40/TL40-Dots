#!/usr/bin/env bash
set -euo pipefail
# Source pretty output definitions
source ../../scripts/lib/pretty-output.sh

# NOTE: These instructions only work for 64-bit Debian-based Linux distributions such as Ubuntu, Mint etc.

# 1. Install Signal's official public software signing key:
echo -e "${LOADING}Installing official signing key...${NC}"
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
sudo mv signal-desktop-keyring.gpg /usr/share/keyrings/signal-desktop-keyring.gpg
echo -e "${GREEN_CHECK}Done!${NC}"

# 2. Add Signal repository to list of repositories:
echo -e "${LOADING}Adding repository...${NC}"
# Detect Ubuntu codename or fallback to xenial if not found
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "xenial")
echo "Detected Ubuntu codename: $UBUNTU_CODENAME"
echo "If this is incorrect, please edit the script and set the correct codename for your distribution."

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt $UBUNTU_CODENAME main" |\
  sudo tee /etc/apt/sources.list.d/signal-desktop.list > /dev/null
echo -e "${GREEN_CHECK}Done!${NC}"

# 3. Update your package database and install Signal:
echo -e "${LOADING}Updating package database...${NC}"
sudo apt update
echo -e "${LOADING}Installing Signal Desktop...${NC}"
sudo apt install -y signal-desktop
echo -e "${GREEN_CHECK}Signal Desktop installed successfully!${NC}"

# 4. Start Signal
echo -e "${LOADING}Starting Signal Desktop...${NC}"
signal-desktop &
echo -e "${INFO}Signal Desktop is starting. You can close this terminal.${NC}"