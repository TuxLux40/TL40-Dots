#!/usr/bin/env bash

set -euo pipefail

echo "Flatpak Restore"

# Scope: default system; set FLATPAK_SCOPE=user to use --user
SCOPE_FLAG="--system"
if [ "${FLATPAK_SCOPE:-system}" = "user" ]; then
  SCOPE_FLAG="--user"
fi

# Temp for GPG key
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
FLATHUB_KEY="$TMPDIR/flathub.gpg"
curl -fsSL https://dl.flathub.org/repo/flathub.gpg -o "$FLATHUB_KEY"

# Add flathub remote (noninteractive)
if ! flatpak remote-list | awk '{print $1}' | grep -qx flathub; then
  flatpak remote-add $SCOPE_FLAG --if-not-exists --gpg-import="$FLATHUB_KEY" flathub https://dl.flathub.org/repo/
fi

# Optional flathub-beta
if [ "${FLATHUB_BETA:-0}" = "1" ]; then
  if ! flatpak remote-list | awk '{print $1}' | grep -qx flathub-beta; then
    flatpak remote-add $SCOPE_FLAG --if-not-exists --gpg-import="$FLATHUB_KEY" flathub-beta https://dl.flathub.org/beta-repo/
  fi
fi

# Restore from list
RESTORE_LIST="${1:-}"
if [ -n "$RESTORE_LIST" ] && [ -f "$RESTORE_LIST" ]; then
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    flatpak install $SCOPE_FLAG -y "$app" || true
  done < "$RESTORE_LIST"
else
  echo "Usage: flatpak-restore.sh /path/to/flatpak-list.txt"
fi

echo "Done."
