#!/usr/bin/env bash

# Post-installation script to set up the environment
# To be installed after the main installation process
# Only for OS/DE independent programs and configurations
# See other scripts for OS/DE specific setups
# Work in progress - use at your own risk

set -euo pipefail

# Source pretty output definitions
source ./scripts/pretty-output.sh

run_step() {
    local stepname="$1"
    shift
    printf "%b%s...%b" "$YELLOW" "$stepname" "$NC"
    if ("$@"); then
        printf "%b%s%b\n" "$GREEN" "✔" "$NC"
    else
        printf "%b%s%b\n" "$RED" "✖" "$NC"
    fi
}

# Directory variables
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
ROOT_DIR="${SCRIPT_DIR}"

# Ensure Atuin config directory exists before any shell integrations touch it
mkdir -p "${HOME}/.config/atuin"

# Source OS detection script
source "${ROOT_DIR}/scripts/detect-os.sh"

# Print detected OS info
printf '\n%bTL40-Dots post-installation%b\n' "${BLUE}" "${NC}"
printf '%bDetected:%b %s (distro: %s, package manager: %s)\n' "${YELLOW}" "${NC}" "$OS_TYPE" "$OS_DISTRO" "$PKG_MANAGER"


# Animated install steps
printf '\n🔧 %bInstalling packages and tools%b\n' "${BLUE}" "${NC}"
run_step "Install base tools" "${ROOT_DIR}/scripts/pkg-scripts/base-tools.sh"
run_step "Install desktop packages" "${ROOT_DIR}/scripts/pkg-scripts/desktop-packages.sh"
run_step "Install Fastfetch" "${ROOT_DIR}/scripts/pkg-scripts/fastfetch-install.sh"
run_step "Install Atuin shell history" "${ROOT_DIR}/scripts/pkg-scripts/atuin-install.sh"
run_step "Install Tailscale" "${ROOT_DIR}/scripts/pkg-scripts/tailscale-install.sh"
run_step "Install Starship prompt" "${ROOT_DIR}/scripts/pkg-scripts/starship-install.sh"
run_step "Install Homebrew" "${ROOT_DIR}/scripts/pkg-scripts/homebrew-install.sh"

# Set Fish as default shell if installed
if command -v fish >/dev/null 2>&1; then
    fish_path=$(command -v fish)
    if [ "$SHELL" != "$fish_path" ]; then
        printf '\n🐠 %bSetting Fish as default shell%b\n' "${YELLOW}" "${NC}"
        chsh -s "$fish_path"
    fi
fi

printf '\n🔗 %bSymlinking dotfiles%b\n' "${BLUE}" "${NC}"
run_step "Symlink configuration files" "${ROOT_DIR}/scripts/postinstall/dotfile-symlinks.sh"

if command -v podman >/dev/null 2>&1; then
    printf '\n🐳 %bPodman detected — enabling socket activation%b\n' "${YELLOW}" "${NC}"
    POSTINSTALL_USER=${SUDO_USER:-$(whoami)}
    "${ROOT_DIR}/scripts/pkg-scripts/podman-postinstall.sh" --user "${POSTINSTALL_USER}" || printf '    🐳 %bFailed to enable podman socket activation.%b\n' "${RED}" "${NC}"
fi

#####################
# Restore shortcuts #
#####################
kde_shortcuts() {
    printf '  ⌨️ %bKDE shortcuts export available.%b\n' "${YELLOW}" "${NC}"
}

gnome_shortcuts() {
    run_step "Restore GNOME shortcuts" "${ROOT_DIR}/scripts/gnome/restore-gnome-shortcuts.sh"
}

no_restore() {
    printf '  ⌨️ %bNo shortcuts restored.%b\n' "${YELLOW}" "${NC}"
}

printf '\n⌨️ %bShortcut restore%b\n' "${GREEN}" "${NC}"
printf '1) KDE\n2) GNOME\n3) None\nChoose: '
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

##########################
# Restore Flatpak apps   #
##########################
if command -v flatpak >/dev/null 2>&1; then
    printf '\n📦 %bRestore Flatpaks?%b (y/n): ' "${GREEN}" "${NC}"
    read -r flatpak_choice
    case "$flatpak_choice" in
        y|Y) run_step "Restore Flatpak applications" "${ROOT_DIR}/scripts/pkg-scripts/flatpak-restore.sh" ;;
        n|N) printf '  📦 %bSkipping Flatpak restore.%b\n' "${YELLOW}" "${NC}" ;;
        *) printf '📦 %bInvalid choice, skipping.%b\n' "${YELLOW}" "${NC}" ;;
    esac
else
    printf '\n📦 %bFlatpak not installed, skipping.%b\n' "${YELLOW}" "${NC}"
fi

#########################
# YubiKey configuration #
#########################
printf '\n🔐 %bConfigure YubiKey now?%b (y/n): ' "${GREEN}" "${NC}"
read -r configure_choice
case "$configure_choice" in
    y|Y) "${ROOT_DIR}/scripts/yk-pam.sh" ;;
    n|N) printf '  🔐 %bRun yk-pam.sh later.%b\n' "${YELLOW}" "${NC}" ;;
    *) printf '🔐 %bInvalid choice.%b\n' "${YELLOW}" "${NC}"; exit 1 ;;
esac

printf '\n✅ %bInstallation complete%b\n' "${GREEN}" "${NC}"