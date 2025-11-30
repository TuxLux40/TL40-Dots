#!/usr/bin/env bash
# Symlink dotfiles from repo to XDG config directories

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Create symlink, force overwrite
link_config() {
    local src="$1" dest="$2"
    if [[ "$dest" == /etc/* ]]; then
        sudo mkdir -p "$(dirname "$dest")"
        sudo rm -rf "$dest"
        sudo ln -s "$src" "$dest"
    else
        mkdir -p "$(dirname "$dest")"
        rm -rf "$dest"
        ln -s "$src" "$dest"
    fi
    echo "Linked: $src -> $dest"
}

# Copy file, force overwrite
copy_config() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    cp -af "$src" "$dest"
    echo "Copied: $src -> $dest"
}

# Link configs
link_config "$REPO_ROOT/config/atuin/config.toml"  "$XDG_CONFIG_HOME/atuin/config.toml"
copy_config "$REPO_ROOT/config/aichat/config.yaml" "$XDG_CONFIG_HOME/aichat/config.yaml"
link_config "$REPO_ROOT/config/.bashrc"            "$HOME/.bashrc"
link_config "$REPO_ROOT/config/starship.toml"      "$XDG_CONFIG_HOME/starship.toml"
link_config "$REPO_ROOT/config/fastfetch"          "$XDG_CONFIG_HOME/fastfetch"
link_config "$REPO_ROOT/config/ghostty/config"     "$XDG_CONFIG_HOME/ghostty/config"
link_config "$REPO_ROOT/config/fish/config.fish"   "$XDG_CONFIG_HOME/fish/config.fish"
link_config "$REPO_ROOT/config/clamav/clamd.conf"  "/etc/clamav/clamd.conf"
link_config "$REPO_ROOT/config/clamav/freshclam.conf" "/etc/clamav/freshclam.conf"
link_config "$REPO_ROOT/config/clamav-milter.conf"     "/etc/clamav/clamav-milter.conf"

echo "All dotfiles symlinked successfully"
