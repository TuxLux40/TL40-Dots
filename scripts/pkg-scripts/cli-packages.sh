#!/usr/bin/env bash

# CLI/TUI Tools Installation
# Installs command-line and terminal-based tools from official repos and AUR

set -e

# Function to check if package would cause conflicts
# Function to check if package is already installed or conflicts with installed packages
is_conflicting() {
    local pkg="$1"
    
    # Check if this exact package is already installed
    if pacman -Q "$pkg" &>/dev/null; then
        return 1  # Already installed, skip
    fi
    
    # Add any known CLI package conflicts here if needed
    # Currently no known CLI conflicts
    
    return 1  # No conflict
}

echo "==================================="
echo "CLI/TUI Tools Installation"
echo "==================================="

# Official repository packages
echo ""
echo "Installing CLI tools from official repositories..."

OFFICIAL_PKGS=(
    aichat aircrack-ng ansible archinstall arpwatch atuin automake autoconf
    azure-cli base-devel bat bind borg borgmatic btop cargo clang clblast
    cmake composer cryptsetup curl davfs2 diffutils diskonaut dnsmasq
    duf fastfetch fish flatpak flatpak-builder flawfinder flawz fsarchiver
    fzf gcc gdb git github-cli glances go gpg-tui grim gum hardinfo2
    htop jq just kismet less llvm lnav ltrace lynis make maven meld
    meson micro nano nbtscan ncdu netctl nfs-utils nikto
    ninja nmap nodejs npm openssh pam-u2f paru pavucontrol pcsc-tools
    perf perl pkg-config podman podman-compose podman-docker promtail pv
    python python-pip python-pipx python-virtualenv python-yubico ranger
    reaver ripgrep rsync ruby rust samba sbctl scrcpy screen
    shellcheck slurp smartmontools snapper sniffnet sshfs 
    starship step-ca step-cli strace sudo tailscale tcpdump tcpflow termshark
    testdisk tmux trash-cli tree tui-journal ttf-jetbrains-mono-nerd
    ttf-nerd-fonts-symbols ufw ugrep unrar unzip uv valgrind 
    virt-manager wget which whois wiki-tui wireguard-tools wireshark-cli
    yarn yq yt-dlp yubico-c-client yubico-pam yubico-piv-tool yubikey-manager
    yubikey-personalization  yubikey-touch-detector
    zoxide
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
echo "Installing CLI tools from AUR..."

AUR_PKGS=(
    azcopy bundletool copilot-cli-bin gpart lazydocker lazygit linutil-bin
    multitail ocrmypdf ollama-docs ollama-rocm pam-duress pam-gnupg pdf2img-c
    pdf2png pdf2svg pdfbox pdfcrack pdfgrep pdfutil powershell-bin nvtop
    ssh-manager-tui sshutils stown superfile tuibox tuifimanager tuner veracrypt gradle metasploit hwinfo
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
echo "✓ CLI/TUI tools installation complete!"
