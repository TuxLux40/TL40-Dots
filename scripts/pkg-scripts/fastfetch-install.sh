#!/usr/bin/env bash

# Fastfetch Installation Script
# Installs fastfetch system information tool

set -e

echo "Installing Fastfetch..."

# Check if fastfetch is already installed
if command -v fastfetch &> /dev/null; then
    echo "Fastfetch is already installed: $(fastfetch --version)"
    exit 0
fi

# Install based on package manager
if command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm --needed fastfetch
elif command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y fastfetch
elif command -v dnf &> /dev/null; then
    sudo dnf install -y fastfetch
elif command -v brew &> /dev/null; then
    brew install fastfetch
else
    echo "ERROR: No supported package manager found (pacman, apt, dnf, brew)"
    exit 1
fi

echo "✓ Fastfetch installed successfully!"
fastfetch --version
