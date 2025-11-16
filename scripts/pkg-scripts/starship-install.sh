#!/usr/bin/env bash
set -euo pipefail

# Install Starship prompt
if command -v starship >/dev/null 2>&1; then
    echo "Starship already installed"
    exit 0
fi

curl -sS https://starship.rs/install.sh | sh -s -- --yes
