#!/usr/bin/env bash

# Miscellaneous packages and systems tools for Arch- and Debian-based systems
# To be consumed by the post-installation script
set -euo pipefail

# Find out the distro to install the correct packages
source /etc/os-release

install_rustup() {
    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
}

debian_packages=(
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
    chezmoi
    starship
    tailscale
    nodejs
    flatpak
    build-essential
    cmake
    ninja
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
    starship
    tailscale
    nodejs
    flatpak
    tldr
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
    chezmoi
    starship
    tailscale
    nodejs
    flatpak
    make
    cmake
    gcc
    ninja
)

install_nerd_font() {
    local font_name="FiraCode"
    local font_dir="${HOME}/.local/share/fonts"
    local font_identifier="FiraCode Nerd Font"
    local font_zip_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${font_name}.zip"
    local tmp_dir

    if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "${font_identifier}"; then
        echo "${font_identifier} already installed."
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required to download Nerd Fonts." >&2
        return 1
    fi

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT

    echo "Downloading ${font_identifier} Nerd Font..."
    curl -L "${font_zip_url}" -o "${tmp_dir}/${font_name}.zip"

    echo "Extracting ${font_identifier} Nerd Font..."
    unzip -o "${tmp_dir}/${font_name}.zip" -d "${tmp_dir}" >/dev/null

    mkdir -p "${font_dir}"
    find "${tmp_dir}" -name '*.ttf' -exec cp {} "${font_dir}" \;

    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "${font_dir}" >/dev/null
    fi

    echo "${font_identifier} installed to ${font_dir}."
    trap - EXIT
    rm -rf "${tmp_dir}"
}

if [[ "$ID" == "debian" || "$ID" == "ubuntu" || "${ID_LIKE:-}" == *debian* ]]; then
    sudo apt update
    sudo apt install -y "${debian_packages[@]}"
    install_rustup
elif [[ "$ID" == "arch" || "${ID_LIKE:-}" == *arch* ]]; then
    sudo pacman -S --color=always --noconfirm --needed "${arch_packages[@]}"
elif [[ "$ID" == "fedora" || "${ID_LIKE:-}" == *rhel* ]]; then
    sudo dnf install -y "${fedora_packages[@]}"
    install_rustup
else
    echo "Unsupported distribution: $ID" >&2
    exit 1
fi

install_nerd_font