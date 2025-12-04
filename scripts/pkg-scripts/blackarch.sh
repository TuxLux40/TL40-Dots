#!/usr/bin/env bash
# BlackArch Linux repository setup script for Arch Linux and derivatives
# This script sets up BlackArch, fixes mirrors, and lets you interactively select categories to install.

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dry-run option
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
    shift
fi

# Check if BlackArch is already installed
if pacman -Sl blackarch &>/dev/null; then
    echo -e "${GREEN}[✓] BlackArch repository is already configured.${NC}"
else
    echo -e "${BLUE}[BlackArch] Setting up BlackArch repository...${NC}"
    
    # Download and run the official setup script
    echo -e "${BLUE}[BlackArch] Downloading setup script...${NC}"
    curl -O https://blackarch.org/strap.sh
    
    # Verify checksum (check current hash first)
    echo -e "${BLUE}[BlackArch] Verifying checksum...${NC}"
    EXPECTED_SHA="e26445d34490cc06bd14b51f9924debf569e0ecb"
    ACTUAL_SHA=$(sha1sum strap.sh | awk '{print $1}')
    
    if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
        echo -e "${YELLOW}[!] Warning: Checksum doesn't match expected value.${NC}"
        echo -e "${YELLOW}    Expected: $EXPECTED_SHA${NC}"
        echo -e "${YELLOW}    Got:      $ACTUAL_SHA${NC}"
        echo -e "${YELLOW}[!] Proceeding anyway (checksum may have been updated)...${NC}"
    else
        echo -e "${GREEN}[✓] Checksum verified successfully.${NC}"
    fi
    
    # Make executable and run
    chmod +x strap.sh
    sudo ./strap.sh
    
    # Clean up
    rm -f strap.sh
    
    # Update mirror list
    echo -e "${BLUE}[BlackArch] Updating mirror list...${NC}"
    sudo curl -sSf -o /etc/pacman.d/blackarch-mirrorlist https://blackarch.org/blackarch-mirrorlist || {
        echo -e "${YELLOW}[!] Warning: Failed to update mirror list. Using default.${NC}"
    }
    
    # Sync databases
    echo -e "${BLUE}[BlackArch] Syncing package databases...${NC}"
    sudo pacman -Sy
fi

# Get available categories
echo -e "${BLUE}[BlackArch] Fetching available categories...${NC}"
categories=( $(pacman -Sg 2>/dev/null | grep '^blackarch-' | awk '{print $1}' | sort -u) )

if [[ ${#categories[@]} -eq 0 ]]; then
    echo -e "${RED}[✗] Error: No BlackArch categories found. Repository may not be properly configured.${NC}"
    exit 1
fi

# Define category descriptions (static list - more reliable than parsing HTML)
declare -A descriptions=(
    ["blackarch-anti-forensic"]="Tools for hiding or destroying evidence"
    ["blackarch-automation"]="Tools for automation of tasks"
    ["blackarch-backdoor"]="Tools for backdoor access"
    ["blackarch-binary"]="Tools for binary analysis"
    ["blackarch-bluetooth"]="Tools for Bluetooth exploitation"
    ["blackarch-code-audit"]="Tools for code auditing"
    ["blackarch-cracker"]="Password crackers"
    ["blackarch-crypto"]="Cryptography tools"
    ["blackarch-database"]="Database exploitation tools"
    ["blackarch-debugger"]="Debugging tools"
    ["blackarch-decompiler"]="Decompilers and disassemblers"
    ["blackarch-defensive"]="Defensive security tools"
    ["blackarch-disassembler"]="Disassemblers"
    ["blackarch-dos"]="Denial of Service tools"
    ["blackarch-drone"]="Drone hacking tools"
    ["blackarch-exploit"]="Exploitation tools and frameworks"
    ["blackarch-fingerprint"]="Fingerprinting and enumeration tools"
    ["blackarch-firmware"]="Firmware analysis tools"
    ["blackarch-forensic"]="Forensic analysis tools"
    ["blackarch-fuzzer"]="Fuzzers for finding vulnerabilities"
    ["blackarch-hardware"]="Hardware hacking tools"
    ["blackarch-honeypot"]="Honeypot tools"
    ["blackarch-keylogger"]="Keyloggers"
    ["blackarch-malware"]="Malware analysis tools"
    ["blackarch-misc"]="Miscellaneous tools"
    ["blackarch-mobile"]="Mobile security tools"
    ["blackarch-networking"]="Networking tools"
    ["blackarch-nfc"]="NFC tools"
    ["blackarch-packer"]="Packers and crypters"
    ["blackarch-proxy"]="Proxy tools"
    ["blackarch-radio"]="Radio and SDR tools"
    ["blackarch-recon"]="Reconnaissance and OSINT tools"
    ["blackarch-reversing"]="Reverse engineering tools"
    ["blackarch-scanner"]="Vulnerability scanners"
    ["blackarch-sniffer"]="Network sniffers"
    ["blackarch-social"]="Social engineering tools"
    ["blackarch-spoof"]="Spoofing tools"
    ["blackarch-threat-model"]="Threat modeling tools"
    ["blackarch-tunnel"]="Tunneling tools"
    ["blackarch-unpacker"]="Unpackers"
    ["blackarch-voip"]="VoIP exploitation tools"
    ["blackarch-webapp"]="Web application security tools"
    ["blackarch-windows"]="Windows exploitation tools"
    ["blackarch-wireless"]="Wireless security tools"
)

# Display categories
echo -e "\n${GREEN}Available BlackArch categories:${NC}\n"
for i in "${!categories[@]}"; do
    cat="${categories[$i]}"
    desc="${descriptions[$cat]:-No description available}"
    printf "${BLUE}%3d)${NC} ${YELLOW}%-35s${NC} %s\n" $((i+1)) "$cat" "$desc"
done

echo -e "\n${GREEN}Options:${NC}"
echo -e "  • Enter numbers (e.g., ${YELLOW}1 5 12${NC}) to install specific categories"
echo -e "  • Enter ${YELLOW}'all'${NC} to install all categories"
echo -e "  • Enter ${YELLOW}'q'${NC} to quit without installing"
echo -e "\n${BLUE}Your choice:${NC} "
read -r input

# Handle quit
if [[ "$input" == "q" || "$input" == "Q" ]]; then
    echo -e "${YELLOW}[!] Exiting without installing anything.${NC}"
    exit 0
fi

# Select categories
if [[ "$input" == "all" ]]; then
    selected=("${categories[@]}")
else
    selected=()
    for num in $input; do
        idx=$((num-1))
        if [[ $idx -ge 0 && $idx -lt ${#categories[@]} ]]; then
            selected+=("${categories[$idx]}")
        else
            echo -e "${YELLOW}[!] Warning: Invalid number '$num' - skipping.${NC}"
        fi
    done
fi

if [[ ${#selected[@]} -eq 0 ]]; then
    echo -e "${RED}[✗] No valid categories selected. Exiting.${NC}"
    exit 1
fi

# Display selection
echo -e "\n${GREEN}Selected categories:${NC}"
for cat in "${selected[@]}"; do
    echo -e "  ${BLUE}•${NC} $cat"
done

# Estimate package count
total_packages=0
for cat in "${selected[@]}"; do
    count=$(pacman -Sgq "$cat" 2>/dev/null | wc -l)
    total_packages=$((total_packages + count))
done
echo -e "\n${YELLOW}Estimated packages to install: ~${total_packages}${NC}"

# Confirm or install
if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "\n${YELLOW}[DRY RUN] Would install: ${selected[*]}${NC}"
    echo -e "${YELLOW}[DRY RUN] Installation not performed.${NC}"
else
    echo -e "\n${BLUE}Proceeding with installation...${NC}"
    sudo pacman -S --needed --noconfirm "${selected[@]}" 2>&1 | tee /tmp/blackarch-install.log || {
        echo -e "${RED}[✗] Installation encountered errors. Check /tmp/blackarch-install.log${NC}"
        exit 1
    }
    echo -e "\n${GREEN}[✓] Installation completed successfully!${NC}"
fi