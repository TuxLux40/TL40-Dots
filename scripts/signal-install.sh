#!/usr/bin/env bash
set -euo pipefail
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
RED_CROSS='\u274C'     # ❌
GREEN_CHECK='\u2705'   # ✅
WARNING='\u26A0\uFE0F' # ⚠️
INFO='\u2139\uFE0F'    # ℹ️
MAG_GLASS='\U1F50D'    # 🔍
LOADING='\u23F3'       # ⏳

# NOTE: These instructions only work for 64-bit Debian-based Linux distributions such as Ubuntu, Mint etc.

# 1. Checking presence of nala, installs it, if not found
if ! command -v nala &>/dev/null; then
  echo -e "${WARNING}Nala not installed, installing it now...${NC}"
  # apt fallback
  sudo apt update -y
  sudo apt install -y nala
  echo -e "${GREEN_CHECK}Nala installed successfully${NC}"
else
  echo -e "${GREEN_CHECK}Nala is installed${NC}"
fi

# 2. Install Signal's official public software signing key:
echo -e "${LOADING}Installing official signing key...${NC}"
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg;
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
echo -e "${GREEN_CHECK}Done!${NC}"

# 3. Add Signal repository to list of repositories:
echo -e "${LOADING}Adding repository...${NC}"
# Detect Ubuntu codename or fallback to xenial if not found
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "xenial")
echo "Detected Ubuntu codename: $UBUNTU_CODENAME"
echo "If this is incorrect, please edit the script and set the correct codename for your distribution."

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt $UBUNTU_CODENAME main" |\
  sudo tee /etc/apt/sources.list.d/signal-desktop.list
echo -e "${GREEN_CHECK}Done!${NC}"

# 4. Update your package database and install Signal:
echo -e "${LOADING}Updating packages and installing Signal... ${NC}"
echo -e "${LOADING}Now starting Signal... ${NC}"
nohup signal-desktop > "$HOME/signal-desktop.log" 2>&1 &
echo -e "${INFO}Signal Desktop is starting in the background. Logs can be found at $HOME/signal-desktop.log${NC}"
echo -e "${GREEN_CHECK}Done!${NC}"

# 5. Start Signal
echo -e "${LOADING}Now starting Signal... ${NC}"
nohup signal-desktop &>/dev/null &