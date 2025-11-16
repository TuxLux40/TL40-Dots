#!/usr/bin/env bash
# OS Detection Script
# This script detects the operating system, distribution, and package manager
# Source this script in other scripts to get OS information

# Exit on error
set -e

# OS Detection Variables
export OS_TYPE=""           # linux, macos, windows
export OS_DISTRO=""         # ubuntu, debian, fedora, arch, etc.
export OS_VERSION=""        # Version number
export OS_CODENAME=""       # Codename if applicable
export PKG_MANAGER=""       # apt, dnf, pacman, brew, etc.
export PKG_INSTALL_CMD=""   # Full install command
export PKG_UPDATE_CMD=""    # Full update command
export PKG_UPGRADE_CMD=""   # Full upgrade command

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS Type
detect_os_type() {
    case "$(uname -s)" in
        Linux*)
            OS_TYPE="linux"
            ;;
        Darwin*)
            OS_TYPE="macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            OS_TYPE="windows"
            ;;
        *)
            log_error "Unknown operating system: $(uname -s)"
            return 1
            ;;
    esac
}

# Detect Linux Distribution
detect_linux_distro() {
    if [[ "$OS_TYPE" != "linux" ]]; then
        return 0
    fi

    # Check for WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        export IS_WSL=true
    else
        export IS_WSL=false
    fi

    # Try /etc/os-release first (most modern distros)
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_DISTRO="${ID}"
        OS_VERSION="${VERSION_ID:-unknown}"
        OS_CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-unknown}}"
        
    # Fallback methods for older systems
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        OS_DISTRO="${DISTRIB_ID,,}"
        OS_VERSION="${DISTRIB_RELEASE}"
        OS_CODENAME="${DISTRIB_CODENAME}"
        
    elif [[ -f /etc/debian_version ]]; then
        OS_DISTRO="debian"
        OS_VERSION=$(cat /etc/debian_version)
        
    elif [[ -f /etc/redhat-release ]]; then
        OS_DISTRO="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oP '\d+\.\d+')
        
    elif [[ -f /etc/arch-release ]]; then
        OS_DISTRO="arch"
        OS_VERSION="rolling"
        
    else
        log_warn "Could not detect Linux distribution"
        OS_DISTRO="unknown"
    fi
}

# Detect macOS Version
detect_macos_version() {
    if [[ "$OS_TYPE" != "macos" ]]; then
        return 0
    fi

    OS_DISTRO="macos"
    OS_VERSION=$(sw_vers -productVersion)
    
    # Determine macOS name based on version
    case "${OS_VERSION%%.*}" in
        15) OS_CODENAME="Sequoia" ;;
        14) OS_CODENAME="Sonoma" ;;
        13) OS_CODENAME="Ventura" ;;
        12) OS_CODENAME="Monterey" ;;
        11) OS_CODENAME="Big Sur" ;;
        10) OS_CODENAME="Catalina or earlier" ;;
        *) OS_CODENAME="Unknown" ;;
    esac
}

# Detect Package Manager
detect_package_manager() {
    case "$OS_TYPE" in
        linux)
            case "$OS_DISTRO" in
                ubuntu|debian|linuxmint|pop|elementary|zorin|kali)
                    PKG_MANAGER="apt"
                    PKG_INSTALL_CMD="sudo apt install -y"
                    PKG_UPDATE_CMD="sudo apt update"
                    PKG_UPGRADE_CMD="sudo apt upgrade -y"
                    ;;
                    
                fedora)
                    PKG_MANAGER="dnf"
                    PKG_INSTALL_CMD="sudo dnf install -y"
                    PKG_UPDATE_CMD="sudo dnf check-update"
                    PKG_UPGRADE_CMD="sudo dnf upgrade -y"
                    ;;
                    
                rhel|centos|rocky|almalinux)
                    if command -v dnf &> /dev/null; then
                        PKG_MANAGER="dnf"
                        PKG_INSTALL_CMD="sudo dnf install -y"
                        PKG_UPDATE_CMD="sudo dnf check-update"
                        PKG_UPGRADE_CMD="sudo dnf upgrade -y"
                    else
                        PKG_MANAGER="yum"
                        PKG_INSTALL_CMD="sudo yum install -y"
                        PKG_UPDATE_CMD="sudo yum check-update"
                        PKG_UPGRADE_CMD="sudo yum upgrade -y"
                    fi
                    ;;
                    
                arch|manjaro|endeavouros|garuda|blendos|cachyos|artix|arcolinux|reborn)
                    PKG_MANAGER="pacman"
                    PKG_INSTALL_CMD="sudo pacman -S --noconfirm"
                    PKG_UPDATE_CMD="sudo pacman -Sy"
                    PKG_UPGRADE_CMD="sudo pacman -Syu --noconfirm"
                    
                    # Check for AUR helpers
                    if command -v paru &> /dev/null; then
                        export AUR_HELPER="paru"
                    elif command -v yay &> /dev/null; then
                        export AUR_HELPER="yay"
                    fi
                    ;;
                    
                opensuse*|sles)
                    PKG_MANAGER="zypper"
                    PKG_INSTALL_CMD="sudo zypper install -y"
                    PKG_UPDATE_CMD="sudo zypper refresh"
                    PKG_UPGRADE_CMD="sudo zypper update -y"
                    ;;
                    
                alpine)
                    PKG_MANAGER="apk"
                    PKG_INSTALL_CMD="sudo apk add"
                    PKG_UPDATE_CMD="sudo apk update"
                    PKG_UPGRADE_CMD="sudo apk upgrade"
                    ;;
                    
                gentoo)
                    PKG_MANAGER="emerge"
                    PKG_INSTALL_CMD="sudo emerge"
                    PKG_UPDATE_CMD="sudo emerge --sync"
                    PKG_UPGRADE_CMD="sudo emerge -uDN @world"
                    ;;
                    
                void)
                    PKG_MANAGER="xbps"
                    PKG_INSTALL_CMD="sudo xbps-install -y"
                    PKG_UPDATE_CMD="sudo xbps-install -S"
                    PKG_UPGRADE_CMD="sudo xbps-install -Su"
                    ;;
                    
                nixos)
                    PKG_MANAGER="nix"
                    PKG_INSTALL_CMD="nix-env -iA nixos."
                    PKG_UPDATE_CMD="sudo nix-channel --update"
                    PKG_UPGRADE_CMD="sudo nixos-rebuild switch --upgrade"
                    ;;
                    
                solus)
                    PKG_MANAGER="eopkg"
                    PKG_INSTALL_CMD="sudo eopkg install -y"
                    PKG_UPDATE_CMD="sudo eopkg update-repo"
                    PKG_UPGRADE_CMD="sudo eopkg upgrade -y"
                    ;;
                    
                *)
                    log_warn "Unknown Linux distribution: $OS_DISTRO"
                    PKG_MANAGER="unknown"
                    ;;
            esac
            ;;
            
        macos)
            if command -v brew &> /dev/null; then
                PKG_MANAGER="brew"
                PKG_INSTALL_CMD="brew install"
                PKG_UPDATE_CMD="brew update"
                PKG_UPGRADE_CMD="brew upgrade"
            else
                log_warn "Homebrew not found on macOS"
                PKG_MANAGER="none"
            fi
            ;;
            
        windows)
            if command -v choco &> /dev/null; then
                PKG_MANAGER="choco"
                PKG_INSTALL_CMD="choco install -y"
                PKG_UPDATE_CMD="choco outdated"
                PKG_UPGRADE_CMD="choco upgrade all -y"
            elif command -v winget &> /dev/null; then
                PKG_MANAGER="winget"
                PKG_INSTALL_CMD="winget install"
                PKG_UPDATE_CMD="winget upgrade"
                PKG_UPGRADE_CMD="winget upgrade --all"
            else
                log_warn "No package manager found on Windows"
                PKG_MANAGER="none"
            fi
            ;;
    esac
}

# Main detection function
detect_os() {
    detect_os_type
    
    case "$OS_TYPE" in
        linux)
            detect_linux_distro
            ;;
        macos)
            detect_macos_version
            ;;
    esac
    
    detect_package_manager
}

# Print OS information
print_os_info() {
    echo "=========================="
    echo "OS Detection Information"
    echo "=========================="
    echo "OS Type:           $OS_TYPE"
    echo "Distribution:      $OS_DISTRO"
    echo "Version:           $OS_VERSION"
    echo "Codename:          $OS_CODENAME"
    echo "Package Manager:   $PKG_MANAGER"
    echo "Install Command:   $PKG_INSTALL_CMD"
    echo "Update Command:    $PKG_UPDATE_CMD"
    echo "Upgrade Command:   $PKG_UPGRADE_CMD"
    
    if [[ -n "$AUR_HELPER" ]]; then
        echo "AUR Helper:        $AUR_HELPER"
    fi
    
    if [[ "$IS_WSL" == "true" ]]; then
        echo "WSL:               Yes"
    fi
    
    echo "=========================="
}

# Check if a package manager command exists
check_package_manager() {
    if [[ "$PKG_MANAGER" == "unknown" ]] || [[ "$PKG_MANAGER" == "none" ]]; then
        log_error "No supported package manager found"
        return 1
    fi
    return 0
}

# Install packages using detected package manager
install_packages() {
    check_package_manager || return 1
    
    log_info "Installing packages: $*"
    $PKG_INSTALL_CMD "$@"
}

# Run the detection
detect_os

# If script is run directly (not sourced), print the information
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_os_info
fi
