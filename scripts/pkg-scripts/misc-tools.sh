#!/usr/bin/env bash

# Miscellaneous packages and systems tools for Arch- and Debian-based systems
# To be consumed by the post-installation script
set -euo pipefail

# Source OS detection script (assume script is run from repo root or scripts/pkg-scripts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR%/scripts/pkg-scripts}"
source "$ROOT_DIR/scripts/detect-os.sh"

install_rustup() {
    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
}

debian_packages=(
    bat
    build-essential
    cmake
    curl
    fish
    flatpak
    fzf
    git
    micro
    ninja
    nodejs
    python3
    python3-pip
    rustc
    tailscale
    trash-cli
    unzip
    wget
    zoxide
)

arch_packages=(
    micro
    trash-cli
    fzf
    zoxide
    bat
    git
    python-pip
    python
    rust
    unzip
    curl
    wget
    systemctl-tui
    archinstall
    bluetui
    systemctl-tui
    cmake
    ninja
    base-devel
    go
    aichat
    fish
    chezmoi
    tailscale
    nodejs
    flatpak
)

fedora_packages=(
    micro
    trash-cli
    fzf
    zoxide
    bat
    git
    python3-pip
    python3
    rustc
    unzip
    curl
    wget
    fish
    tailscale
    nodejs
    flatpak
    make
    cmake
    gcc
    ninja
)