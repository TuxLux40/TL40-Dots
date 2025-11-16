#!/bin/bash -e

# Check if paru is already installed
if command -v paru >/dev/null 2>&1; then
    echo "paru is already installed."
    exit 0
fi

# Install paru AUR helper
set -e
# Install base-devel group if not already installed
sudo pacman -S --needed base-devel
# clone paru repository and check for success before cding into it
if git clone https://aur.archlinux.org/paru.git; then
    cd paru
else
    echo "Error: Failed to clone paru repository."
    exit 1
fi
# build and install paru
makepkg -si