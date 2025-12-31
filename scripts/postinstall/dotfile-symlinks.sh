#!/usr/bin/env bash
# Symlink dotfiles from repo to XDG config directories using GNU Stow

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow is not installed"
    echo "Install with: sudo pacman -S stow"
    exit 1
fi

echo "Linking dotfiles with GNU Stow..."
cd "$REPO_ROOT"

# Link all config packages to ~/.config (except kde, containers and clamav) - they will be handled separately
EXCLUDE_PACKAGES=("kde" "containers" "clamav" "aichat" "system.yaml")

for package_dir in config/*/; do
    package=$(basename "$package_dir")
    
    # Skip excluded packages and files
    skip=false
    for excluded in "${EXCLUDE_PACKAGES[@]}"; do
        if [[ "$package" == "$excluded" ]]; then
            skip=true
            break
        fi
    done
    
    if [[ "$skip" == true ]] || [[ ! -d "$package_dir" ]]; then
        continue
    fi
    
    echo "Linking $package..."
    stow -d config -t "$XDG_CONFIG_HOME" --override='.*' "$package" 2>/dev/null || echo "  Warning: Could not link $package"
done

# Link/copy individual config files in root of config/
ln -sf "$REPO_ROOT/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
mkdir -p "$XDG_CONFIG_HOME/aichat" && cp -f "$REPO_ROOT/config/aichat/config.yaml" "$XDG_CONFIG_HOME/aichat/config.yaml"

# Link KDE configs using stow (only if KDE is installed)
if command -v plasmashell &> /dev/null || command -v plasma-desktop &> /dev/null; then
    echo "Linking KDE configs..."
    stow -d config -t "$XDG_CONFIG_HOME" --override='.*' kde
    echo "  KDE configs linked"
else
    echo "  KDE not detected, skipping KDE configs"
fi

# Link system configs to /etc (requires sudo)
if [[ -d "$REPO_ROOT/config/clamav" ]]; then
    echo "Linking system configs (requires sudo)..."
    sudo mkdir -p /etc/clamav
    for conf in "$REPO_ROOT/config/clamav"/*.conf; do
        if [[ -f "$conf" ]]; then
            sudo ln -sf "$conf" "/etc/clamav/$(basename "$conf")"
            echo "  Linked $(basename "$conf") to /etc/clamav"
        fi
    done
fi

echo ""
echo "Done! All dotfiles symlinked."
echo "New configs added to config/ will be automatically linked on next run."