#!/usr/bin/env bash
# Installation script for TL40-Dots
# Clones the repository and runs the post-installation script

set -euo pipefail

# Colors and symbols for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
CHECK='✅'
WARN='⚠'

# Clone the repository
git clone https://github.com/yourusername/TL40-Dots
cd TL40-Dots

# Run the post-installation script
"${PWD}/scripts/postinstall/postinstall.sh"
# Check for successful installation
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}${CHECK} TL40-Dots installation complete!${NC}"
else
    echo -e "${YELLOW}${WARN} Installation encountered issues. Please check the output above.${NC}"
    exit 1
fi
exit 0

# Check if installation was successful and print messages
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}${CHECK} TL40-Dots installation complete!${NC}"
else
    echo -e "${YELLOW}${WARN} Installation encountered issues. Please check the output above.${NC}"
    exit 1
fi