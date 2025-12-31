#!/bin/bash
set -euo pipefail

# Script to download, install, and configure rclone
# Downloads the latest rclone binary, installs it to system, and sets up manpage

RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-amd64.zip"
DOWNLOAD_DIR="${HOME}/Downloads"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create Downloads directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

echo "Fetching and unpacking rclone..."
cd "$TEMP_DIR"
curl -L "$RCLONE_URL" -o rclone.zip
unzip -q rclone.zip
RCLONE_DIR=$(ls -d rclone-*-linux-amd64 2>/dev/null | head -1)

if [[ ! -d "$RCLONE_DIR" ]]; then
    echo "Error: Could not find rclone directory in extraction"
    exit 1
fi

cd "$RCLONE_DIR"

echo "Installing rclone binary..."
sudo cp rclone /usr/bin/
sudo chown root:root /usr/bin/rclone
sudo chmod 755 /usr/bin/rclone

echo "Installing manpage..."
sudo mkdir -p /usr/local/share/man/man1
sudo cp rclone.1 /usr/local/share/man/man1/
sudo mandb > /dev/null 2>&1 || true

echo "Installation complete!"
echo ""
echo "Run 'rclone config' to set up your remote storage:"
rclone config