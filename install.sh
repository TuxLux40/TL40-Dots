#!/usr/bin/env bash

# Post-installation script to set up the environment
# To be installed after the main installation process
# Only for OS/DE independent programs and configurations
# See other scripts for OS/DE specific setups
# Work in progress - use at your own risk

set -euo pipefail

# Spinner and animated step output
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        spinstr=$temp${spinstr%$temp}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "     \b\b\b\b\b"
}

run_step() {
    local stepname="$1"
    shift
    printf "%b%s...%b" "$YELLOW" "$stepname" "$NC"
    ("$@") &
    local pid=$!
    spinner $pid
    wait $pid
    local status=$?
    if [ $status -eq 0 ]; then
        printf "%b%s%b\n" "$GREEN" "✔" "$NC"
    else
        printf "%b%s%b\n" "$RED" "✖" "$NC"
    fi
    return $status
}

# Source pretty output definitions
source ./scripts/pretty-output.sh

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
printf '\n%bInstalling packages and tools%b\n' "${BLUE}" "${NC}"
run_step "Install miscellaneous tools" "${ROOT_DIR}/scripts/pkg-scripts/misc-tools.sh"
run_step "Install Fastfetch" "${ROOT_DIR}/scripts/pkg-scripts/fastfetch-install.sh"
run_step "Install Atuin shell history" "${ROOT_DIR}/scripts/pkg-scripts/atuin-install.sh"
run_step "Install Tailscale" "${ROOT_DIR}/scripts/pkg-scripts/tailscale-install.sh"
run_step "Install Starship prompt" "${ROOT_DIR}/scripts/pkg-scripts/starship-install.sh"
run_step "Install Homebrew" "${ROOT_DIR}/scripts/pkg-scripts/homebrew-install.sh"

# Set Fish as default shell if installed
if command -v fish >/dev/null 2>&1; then
    fish_path=$(command -v fish)
    if [ "$SHELL" != "$fish_path" ]; then
        printf '\n%bSetting Fish as default shell%b\n' "${YELLOW}" "${NC}"
        chsh -s "$fish_path"
    fi
fi

printf '\n%bSymlinking dotfiles%b\n' "${BLUE}" "${NC}"
run_step "Symlink configuration files" "${ROOT_DIR}/scripts/postinstall/dotfile-symlinks.sh"

if command -v podman >/dev/null 2>&1; then
    printf '\n%bPodman detected — enabling socket activation%b\n' "${YELLOW}" "${NC}"
    POSTINSTALL_USER=${SUDO_USER:-$(whoami)}
    "${ROOT_DIR}/scripts/pkg-scripts/podman-postinstall.sh" --user "${POSTINSTALL_USER}" || printf '    %bFailed to enable podman socket activation.%b\n' "${RED}" "${NC}"
fi

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

##########################
# Restore Flatpak apps   #
##########################
if command -v flatpak >/dev/null 2>&1; then
    printf '\n%bRestore Flatpak applications?%b\n' "${GREEN}" "${NC}"
    printf '  y) Yes, restore Flatpaks\n'
    printf '  n) No, skip Flatpaks\n'
    printf 'Selection (y/n): '
    read -r flatpak_choice
    
    case "$flatpak_choice" in
        y|Y)
            run_step "Restore Flatpak applications" "${ROOT_DIR}/scripts/pkg-scripts/flatpaks-install.sh"
            ;;
        n|N)
            printf '  %bSkipping Flatpak restore.%b\n' "${YELLOW}" "${NC}"
            ;;
        *)
            printf '%bInvalid choice, skipping Flatpaks.%b\n' "${YELLOW}" "${NC}"
            ;;
    esac
else
    printf '\n%bFlatpak not installed, skipping.%b\n' "${YELLOW}" "${NC}"
fi

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

printf '\n%b✅ Installation complete!%b\n' "${GREEN}" "${NC}"
printf '\n%b %bPost-installation script completed.%b\n' "${CHECK}" "${GREEN}" "${NC}"