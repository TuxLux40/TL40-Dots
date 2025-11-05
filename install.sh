#!/usr/bin/env bash

# Post-installation script to set up the environment
# To be installed after the main installation process
# Only for OS/DE independent programs and configurations
# See other scripts for OS/DE specific setups
# Work in progress - use at your own risk

set -euo pipefail

# Colors and symbols for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color
CHECK='✅'

# Directory variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

#################################
# Detect OS and package manager #
#################################
detect_distro() {
    local id_lc=""
    local id_like_lc=""

    OS_NAME="$(uname -s)"
    OS_FAMILY="unknown"
    PKG_MANAGER="unknown"

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_NAME="${PRETTY_NAME:-$NAME}"
        id_lc="${ID,,}"
        if [[ -n "${ID_LIKE:-}" ]]; then
            id_like_lc="${ID_LIKE,,}"
        fi

        case "${id_lc}" in
            arch|artix|manjaro|endeavouros|garuda|cachyos)
                OS_FAMILY="arch"
                PKG_MANAGER="pacman"
                ;;
            debian|ubuntu|pop|linuxmint|elementary|zorin|kali|raspbian|tuxedo|neon)
                OS_FAMILY="debian"
                PKG_MANAGER="apt"
                ;;
            fedora|rhel|centos|rocky|almalinux|oracle|amazon|alma|rockylinux)
                OS_FAMILY="fedora"
                PKG_MANAGER="dnf"
                ;;
            opensuse*|sles)
                OS_FAMILY="suse"
                PKG_MANAGER="zypper"
                ;;
            alpine)
                OS_FAMILY="alpine"
                PKG_MANAGER="apk"
                ;;
            *)
                if [[ "${id_like_lc}" == *arch* ]]; then
                    OS_FAMILY="arch"
                    PKG_MANAGER="pacman"
                elif [[ "${id_like_lc}" == *debian* ]]; then
                    OS_FAMILY="debian"
                    PKG_MANAGER="apt"
                elif [[ "${id_like_lc}" == *rhel* || "${id_like_lc}" == *fedora* ]]; then
                    OS_FAMILY="fedora"
                    PKG_MANAGER="dnf"
                elif [[ "${id_like_lc}" == *suse* ]]; then
                    OS_FAMILY="suse"
                    PKG_MANAGER="zypper"
                fi
                ;;
        esac
    fi

    if [[ "${PKG_MANAGER}" == "unknown" ]]; then
        if [[ -x /usr/local/bin/brew ]]; then
            OS_FAMILY="darwin"
            PKG_MANAGER="brew"
        elif command -v brew >/dev/null 2>&1; then
            OS_FAMILY="darwin"
            PKG_MANAGER="brew"
        fi
    fi
}
# Helper to run installation only if binary is missing
run_if_missing() {
    local description="$1"
    local binary_name="$2"
    shift 2

    printf '\n%s%s%s\n' "${GREEN}" "${description}" "${NC}"
    if command -v "${binary_name}" >/dev/null 2>&1; then
        printf '    %s↳ %s already installed. Skipping.%s\n' "${YELLOW}" "${binary_name}" "${NC}"
        return 0
    fi

    "$@"
    printf '    %s↳ Completed.%s\n' "${YELLOW}" "${NC}"
}
# Clear any previously set environment variables
unset OS_NAME OS_FAMILY PKG_MANAGER
detect_distro
export OS_NAME OS_FAMILY PKG_MANAGER
# Detecting operating system and package manager
printf '\n%sTL40-Dots post-installation%s\n' "${BLUE}" "${NC}"
printf '%sDetected:%s %s (package manager: %s)\n' "${YELLOW}" "${NC}" "${OS_NAME}" "${PKG_MANAGER}"

#############################################
# Running miscellaneous installation scripts#
##############################################
printf '\n%s[1/6]%s Ensure Fish shell is installed\n' "${GREEN}" "${NC}"
"${ROOT_DIR}/scripts/pkg-scripts/fish-install.sh"
printf '%s    ↳ Fish shell ready.%s\n' "${YELLOW}" "${NC}"

run_if_missing "[2/6] Install Atuin shell history" atuin "${ROOT_DIR}/scripts/pkg-scripts/atuin-install.sh"

run_if_missing "[3/6] Install Tailscale" tailscale "${ROOT_DIR}/scripts/pkg-scripts/tailscale-install.sh"

run_if_missing "[4/6] Install Starship prompt" starship "${ROOT_DIR}/scripts/pkg-scripts/starship-install.sh" --yes

run_if_missing "[5/6] Install ChezMoi" chezmoi "${ROOT_DIR}/scripts/pkg-scripts/chezmoi-install.sh"

run_if_missing "[6/6] Install Homebrew" brew "${ROOT_DIR}/scripts/pkg-scripts/homebrew-install.sh"

printf '\n%sSymlinking dotfiles%s\n' "${GREEN}" "${NC}"
"${ROOT_DIR}/scripts/postinstall/dotfile-symlinks.sh"
printf '%s    ↳ Dotfile links updated.%s\n' "${YELLOW}" "${NC}"

#####################
# Restore shortcuts #
#####################
kde_shortcuts() {
    printf '  %sKDE shortcuts restored.%s\n' "${YELLOW}" "${NC}"
}

gnome_shortcuts() {
    printf '  %sGNOME shortcuts restored.%s\n' "${YELLOW}" "${NC}"
}

no_restore() {
    printf '  %sNo shortcuts restored.%s\n' "${YELLOW}" "${NC}"
}

printf '\n%sShortcut restore options%s\n' "${GREEN}" "${NC}"
printf '  1) KDE Shortcuts\n'
printf '  2) GNOME Shortcuts\n'
printf '  3) No shortcuts\n'
printf 'Selection (1/2/3): '
read -r choice

case "$choice" in
    1) 
        # Restore KDE shortcuts
        kde_shortcuts 
        ;;
    2) 
        # Restore GNOME shortcuts
        gnome_shortcuts 
        ;;
    3) 
        # Do not restore any shortcuts
        no_restore 
        ;;
    *)
        # Handle invalid selection
        printf '%sInvalid selection.%s\n' "${YELLOW}" "${NC}"
        exit 1
        ;;
esac

sleep 2

#########################
# YubiKey configuration #
#########################
configure_now() {
    printf '  %sConfiguring YubiKey...%s\n' "${YELLOW}" "${NC}"
    "${ROOT_DIR}/scripts/yubikey-setup.sh"
}
configure_later() {
    printf '  %sYou can run yubikey-setup.sh later to configure your key.%s\n' "${YELLOW}" "${NC}"
}
printf '\n%sYubiKey configuration%s\n' "${GREEN}" "${NC}"
printf '  y) Configure now\n'
printf '  n) Configure later\n'
printf 'Selection (y/n): '
read -r configure_choice
case "$configure_choice" in
    y|Y)
        configure_now
        ;;
    n|N)
        configure_later
        ;;
    *)
        printf '%sInvalid choice.%s\n' "${YELLOW}" "${NC}"
        exit 1
        ;;
esac

##########################
# Restoring Flatpak apps #
##########################

printf '\n%s %sPost-installation script completed.%s\n' "${CHECK}" "${GREEN}" "${NC}"