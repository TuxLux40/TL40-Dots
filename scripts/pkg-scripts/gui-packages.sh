#!/usr/bin/env bash

# GUI Applications Installation
# Installs graphical desktop applications from official repos and AUR

set -e

# Function to check if package would cause conflicts
# Function to check if package is already installed or conflicts with installed packages
is_conflicting() {
    local pkg="$1"
    
    # Check if this exact package is already installed
    if pacman -Q "$pkg" &>/dev/null; then
        return 1  # Already installed, skip
    fi
    
    # Check for known conflicts
    case "$pkg" in
        obs-studio-stable)
            # obs-studio-stable conflicts with obs-studio
            if pacman -Q obs-studio &>/dev/null; then
                return 0  # Conflict detected
            fi
            ;;
        obs-studio)
            # obs-studio conflicts with obs-studio-stable
            if pacman -Q obs-studio-stable &>/dev/null; then
                return 0  # Conflict detected
            fi
            ;;
        dotnet-sdk-bin)
            # dotnet-sdk-bin conflicts with dotnet-host
            if pacman -Q dotnet-host &>/dev/null; then
                return 0  # Conflict detected
            fi
            ;;
    esac
    
    return 1  # No conflict
}

echo "==================================="
echo "GUI Applications Installation"
echo "==================================="

# Official repository packages
echo ""
echo "Installing GUI applications from official repositories..."

OFFICIAL_PKGS=(
    gimp gnome-boxes gparted libreoffice-fresh lmms mousepad mpv obs-studio
    qalculate-gtk retroarch seahorse shotcut steam vlc vlc-plugins-extra
)

INSTALL_PKGS=()
SKIP_PKGS=()

for pkg in "${OFFICIAL_PKGS[@]}"; do
    if ! is_conflicting "$pkg"; then
        INSTALL_PKGS+=("$pkg")
    else
        SKIP_PKGS+=("$pkg")
    fi
done

if [ ${#SKIP_PKGS[@]} -gt 0 ]; then
    echo "⚠ Skipping packages due to conflicts: ${SKIP_PKGS[*]}"
fi

if [ ${#INSTALL_PKGS[@]} -gt 0 ]; then
    sudo pacman -S --noconfirm --needed "${INSTALL_PKGS[@]}"
fi

# AUR packages
echo ""
echo "Installing GUI applications from AUR..."

AUR_PKGS=(
    android-file-transfer audacity ausweisapp2
    brave-beta-bin brave-bin discord digikam
    dotnet-sdk-8.0 dotnet-sdk-bin emudeck filezilla ghostty github-desktop-bin
    gnac google-chrome impala jellyfin-ffmpeg jellyfin-media-player
    masterpdfeditor-free microsoft-edge-stable-bin mission-center obs-studio-stable
    octopi openrgb paperwork pdfarranger php-imagick podman-desktop
    powershell-editor-services proton-mail-bin proton-pass-bin protonmail-bridge
    qemu-emulators-full rpi-imager scratch
    signal-desktop-beta spytrap-adb surge-xt sweethome3d
    ttf-meslo-nerd-font-powerlevel10k visual-studio-code-bin
    yubico-authenticator-bin zed zapzap win11-gtk-theme-git win11-icon-theme-git
)

INSTALL_AUR_PKGS=()
SKIP_AUR_PKGS=()

for pkg in "${AUR_PKGS[@]}"; do
    if ! is_conflicting "$pkg"; then
        INSTALL_AUR_PKGS+=("$pkg")
    else
        SKIP_AUR_PKGS+=("$pkg")
    fi
done

if [ ${#SKIP_AUR_PKGS[@]} -gt 0 ]; then
    echo "⚠ Skipping AUR packages due to conflicts: ${SKIP_AUR_PKGS[*]}"
fi

if [ ${#INSTALL_AUR_PKGS[@]} -gt 0 ]; then
    paru -S --noconfirm --needed "${INSTALL_AUR_PKGS[@]}"
fi

echo ""
echo "✓ GUI applications installation complete!"
