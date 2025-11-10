#!/usr/bin/env sh

# Post-installation script to set up the environment
# To be installed after the main installation process
# Only for OS/DE independent programs and configurations
# See other scripts for OS/DE specific setups
# Work in progress - use at your own risk

set -eu

# Source pretty output definitions
. ./scripts/pretty-output.sh

# Directory variables
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
ROOT_DIR="${SCRIPT_DIR}"

# Ensure Atuin config directory exists before any shell integrations touch it
mkdir -p "${HOME}/.config/atuin"

# Helper to run installation only if binary is missing
run_if_missing() {
    description="$1"
    binary_name="$2"
    shift 2

    printf '\n%b%b%b\n' "${GREEN}" "${description}" "${NC}"
    if command -v "${binary_name}" >/dev/null 2>&1; then
        printf '    %b%b %s already installed. Skipping.%b\n' "${YELLOW}" "${CHECK}" "${binary_name}" "${NC}"
        return 0
    fi

    "$@"
    printf '    %b%b Completed.%b\n' "${YELLOW}" "${CHECK}" "${NC}"
}
# Basic host info for logging
OS_NAME=$(uname -s)
OS_FAMILY="unknown"
PKG_MANAGER="unknown"
# Export so called scripts can re-use
export OS_NAME OS_FAMILY PKG_MANAGER
# Detecting operating system and package manager
printf '\n%bTL40-Dots post-installation%b\n' "${BLUE}" "${NC}"
printf '%bDetected:%b %s (package manager: %s)\n' "${YELLOW}" "${NC}" "${OS_NAME}" "${PKG_MANAGER}"

#############################################
# Running miscellaneous installation scripts#
##############################################
run_if_missing "[1/7] Install miscellaneous tools" micro "${ROOT_DIR}/scripts/pkg-scripts/misc-tools.sh"

run_if_missing "[2/7] Install Fastfetch" fastfetch "${ROOT_DIR}/scripts/pkg-scripts/fastfetch-install.sh"

# Set Fish as default shell if installed
if command -v fish >/dev/null 2>&1; then
    fish_path=$(command -v fish)
    if [ "$SHELL" != "$fish_path" ]; then
        chsh -s "$fish_path"
    fi
fi

run_if_missing "[3/7] Install Atuin shell history" atuin "${ROOT_DIR}/scripts/pkg-scripts/atuin-install.sh"

run_if_missing "[4/7] Install Tailscale" tailscale "${ROOT_DIR}/scripts/pkg-scripts/tailscale-install.sh"

run_if_missing "[5/7] Install Starship prompt" starship "${ROOT_DIR}/scripts/pkg-scripts/starship-install.sh" --yes
run_if_missing "[6/7] Install Zoxide" zoxide "${ROOT_DIR}/scripts/pkg-scripts/zoxide-install.sh"
run_if_missing "[7/7] Install Homebrew" brew "${ROOT_DIR}/scripts/pkg-scripts/homebrew-install.sh"

printf '\n%bSymlinking dotfiles%b\n' "${GREEN}" "${NC}"
"${ROOT_DIR}/scripts/postinstall/dotfile-symlinks.sh"
printf '%b    ↳ All configs symlinked.%b\n' "${YELLOW}" "${NC}"

#####################
# Restore shortcuts #
#####################
kde_shortcuts() {
    printf '  %bKDE shortcuts restored.%b\n' "${YELLOW}" "${NC}"
}

gnome_shortcuts() {
    printf '  %bGNOME shortcuts restored.%b\n' "${YELLOW}" "${NC}"
}

no_restore() {
    printf '  %bNo shortcuts restored.%b\n' "${YELLOW}" "${NC}"
}

printf '\n%bShortcut restore options%b\n' "${GREEN}" "${NC}"
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
    printf '%bInvalid selection.%b\n' "${YELLOW}" "${NC}"
        exit 1
        ;;
esac

sleep 2

#########################
# YubiKey configuration #
#########################
configure_now() {
    printf '  %bConfiguring YubiKey...%b\n' "${YELLOW}" "${NC}"
    "${ROOT_DIR}/scripts/yk-pam.sh"
}
configure_later() {
    printf '  %bYou can run yk-pam.sh later to configure your key.%b\n' "${YELLOW}" "${NC}"
}
printf '\n%bYubiKey configuration%b\n' "${GREEN}" "${NC}"
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
    printf '%bInvalid choice.%b\n' "${YELLOW}" "${NC}"
        exit 1
        ;;
esac

##########################
# Restoring Flatpak apps #
##########################

printf '\n%b %bPost-installation script completed.%b\n' "${CHECK}" "${GREEN}" "${NC}"