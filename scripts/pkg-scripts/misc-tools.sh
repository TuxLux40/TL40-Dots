#!/usr/bin/env bash

# Miscellaneous packages and systems tools for Arch- and Debian-based systems
# To be consumed by the post-installation script
set -euo pipefail

# Find out the distro to install the correct packages
source /etc/os-release

common_packages=(
    micro
    trash-cli
    fzf
    zoxide
    fastfetch
    rustup
    bat
    git
    python-pip
    python
    rust
)

arch_only_packages=(
    systemctl-tui
    archinstall
    bluetui
    systemctl-tui
    cmake
    ninja
    base-devel
    go
)

if [[ "$ID" == "debian" || "$ID" == "ubuntu" || "${ID_LIKE:-}" == *debian* ]]; then
    sudo apt install -y "${common_packages[@]}"
elif [[ "$ID" == "arch" || "${ID_LIKE:-}" == *arch* ]]; then
    sudo pacman -S --color=always --noconfirm --needed "${common_packages[@]}" "${arch_only_packages[@]}"
else
    echo "Unsupported distribution: $ID" >&2
    exit 1
fi