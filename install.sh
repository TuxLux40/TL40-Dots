#!/usr/bin/env bash

# Post-installation script to set up the environment
# To be installed after the main installation process
# Only for OS/DE independent programs and configurations
# See other scripts for OS/DE specific setups
# Work in progress - use at your own risk

set -euo pipefail

# Source pretty output definitions
source ./scripts/lib/pretty-output.sh

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

# Ask user whether to run, skip, or quit a step (minimal interactive wrapper)
ask_run_step() {
    local stepname="$1"; shift
    local cmd=("$@")
    printf '\n%bStep:%b %s\n' "$BLUE" "$NC" "$stepname"
    local opts=("Run" "Skip" "Quit")
    local sel
    sel=$(select_option "${opts[@]}")
    case "$sel" in
        0) run_step "$stepname" "${cmd[@]}" ;;
        1) printf "%bSkipped:%b %s\n" "$YELLOW" "$NC" "$stepname" ;;
        2) printf "%bAborting at user request.%b\n" "$RED" "$NC"; exit 0 ;;
    esac
}

select_option() {
    local options=("$@")
    local selected=0
    local num_options=${#options[@]}
    while true; do
        for ((i=0; i<num_options; i++)); do
            if [ $i -eq $selected ]; then
                printf "\e[7m%s\e[0m\n" "${options[$i]}" >&2
            else
                printf "%s\n" "${options[$i]}" >&2
            fi
        done
        read -s -n1 key
        if [ "$key" = $'\e' ]; then
            read -s -n1 key2
            if [ "$key2" = '[' ]; then
                read -s -n1 key3
                if [ "$key3" = 'A' ]; then
                    ((selected--))
                    if [ $selected -lt 0 ]; then selected=$((num_options-1)); fi
                elif [ "$key3" = 'B' ]; then
                    ((selected++))
                    if [ $selected -ge $num_options ]; then selected=0; fi
                fi
            fi
        elif [ "$key" = $'\n' ] || [ "$key" = '' ]; then
            break
        fi
        # move cursor up to redraw menu
        tput cuu $num_options >&2
    done
    printf "\n" >&2
    echo "$selected"
}

# Directory variables
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
ROOT_DIR="${SCRIPT_DIR}"

# Ensure Atuin config directory exists before any shell integrations touch it
mkdir -p "${HOME}/.config/atuin"

# Source OS detection script
source "${ROOT_DIR}/scripts/lib/detect-os.sh"

# Print detected OS info
printf '\n%bTL40-Dots post-installation%b\n' "${BLUE}" "${NC}"
printf '%bDetected:%b %s (distro: %s, package manager: %s)\n' "${YELLOW}" "${NC}" "$OS_TYPE" "$OS_DISTRO" "$PKG_MANAGER"


# Interactive install steps (each can be Run/Skip/Quit)
printf '\n🔧 %bInstalling packages and tools (interactive)%b\n' "${BLUE}" "${NC}"
ask_run_step "Install base tools" "${ROOT_DIR}/scripts/pkg-scripts/base-tools.sh"
ask_run_step "Install desktop packages" "${ROOT_DIR}/scripts/pkg-scripts/desktop-packages.sh"
ask_run_step "Install Fastfetch" "${ROOT_DIR}/scripts/pkg-scripts/fastfetch-install.sh"
ask_run_step "Install Atuin shell history" "${ROOT_DIR}/scripts/pkg-scripts/atuin-install.sh"
ask_run_step "Install Tailscale" "${ROOT_DIR}/scripts/pkg-scripts/tailscale-install.sh"
ask_run_step "Install Starship prompt" "${ROOT_DIR}/scripts/pkg-scripts/starship-install.sh"
ask_run_step "Install Homebrew" "${ROOT_DIR}/scripts/pkg-scripts/homebrew-install.sh"
ask_run_step "Install OpenRGB udev rules" "${ROOT_DIR}/scripts/hardware/openrgb-udev-install.sh"

# Set Fish as default shell if installed
if command -v fish >/dev/null 2>&1; then
    fish_path=$(command -v fish)
    if [ "$SHELL" != "$fish_path" ]; then
        printf '\n🐠 %bSetting Fish as default shell%b\n' "${YELLOW}" "${NC}"
        chsh -s "$fish_path"
    fi
fi

printf '\n🔗 %bSymlinking dotfiles (interactive)%b\n' "${BLUE}" "${NC}"
ask_run_step "Symlink configuration files" "${ROOT_DIR}/scripts/postinstall/dotfile-symlinks.sh"
ask_run_step "Symlink NAS shares" "${ROOT_DIR}/scripts/postinstall/nas-symlinks.sh"

if command -v podman >/dev/null 2>&1; then
    POSTINSTALL_USER=${SUDO_USER:-$(whoami)}
    ask_run_step "Podman socket activation" "${ROOT_DIR}/scripts/pkg-scripts/podman-postinstall.sh" --user "${POSTINSTALL_USER}"
fi

#####################
# Restore shortcuts #
#####################
kde_shortcuts() {
    printf '  ⌨️ %bKDE shortcuts export available.%b\n' "${YELLOW}" "${NC}"
}

gnome_shortcuts() {
    run_step "Restore GNOME shortcuts" "${ROOT_DIR}/scripts/desktop/gnome/restore-gnome-shortcuts.sh"
}

no_restore() {
    printf '  ⌨️ %bNo shortcuts restored.%b\n' "${YELLOW}" "${NC}"
}

printf '\n⌨️ %bShortcut restore%b\n' "${GREEN}" "${NC}"
options=("KDE" "GNOME" "None")
selected=$(select_option "${options[@]}")
case "$selected" in
    0) kde_shortcuts ;;
    1) gnome_shortcuts ;;
    2) no_restore ;;
esac

##########################
# Restore Flatpak apps   #
##########################
if command -v flatpak >/dev/null 2>&1; then
    printf '\n📦 %bRestore Flatpaks?%b\n' "${GREEN}" "${NC}"
    options=("Yes" "No")
    selected=$(select_option "${options[@]}")
    case "$selected" in
        0) run_step "Restore Flatpak applications" "${ROOT_DIR}/scripts/pkg-scripts/flatpak-restore.sh" ;;
        1) printf '  📦 %bSkipping Flatpak restore.%b\n' "${YELLOW}" "${NC}" ;;
    esac
else
    printf '\n📦 %bFlatpak not installed, skipping.%b\n' "${YELLOW}" "${NC}"
fi

#########################
# YubiKey configuration #
#########################
printf '\n🔐 %bConfigure YubiKey now?%b\n' "${GREEN}" "${NC}"
options=("Yes" "No")
selected=$(select_option "${options[@]}")
case "$selected" in
    0) "${ROOT_DIR}/scripts/system-setup/yubikey-pam-setup.sh" ;;
    1) printf '  🔐 %bRun yk-pam.sh later.%b\n' "${YELLOW}" "${NC}" ;;
esac

printf '\n✅ %bInstallation complete%b\n' "${GREEN}" "${NC}"