#!/bin/sh -e

# This script installs the paru AUR helper for Arch Linux systems using pacman.
# It checks if paru is already installed and installs it from the AUR if not.
# The script sources common-script.sh for shared utilities and sets AUR_HELPER_CHECKED to true.
# It defines the installDepend function which handles the installation process.
# The function supports only pacman as the package manager; other managers are unsupported.
# It uses the ESCALATION_TOOL (e.g., sudo) for privileged operations.
# The script calls checkEnv, checkEscalationTool, and installDepend in sequence.

. ../../common-script.sh

AUR_HELPER_CHECKED=true

installDepend() {
    case "$PACKAGER" in
        pacman)
            if ! command_exists paru; then
                printf "%b\n" "${YELLOW}Installing paru as AUR helper...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm base-devel git
                cd /opt && "$ESCALATION_TOOL" git clone https://aur.archlinux.org/paru-bin.git && "$ESCALATION_TOOL" chown -R "$USER": ./paru-bin
                cd paru-bin && makepkg --noconfirm -si
                printf "%b\n" "${GREEN}Paru installed${RC}"
            else
                printf "%b\n" "${GREEN}Paru already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installDepend