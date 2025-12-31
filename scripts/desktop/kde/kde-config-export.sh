#!/bin/bash
# Script to export the current KDE theme and settings to a file in /output
DATESTAMP=$(date +%Y%m%d)
REPO_ROOT="$(git rev-parse --show-toplevel)"
EXPDIR="${1:-${KDE_THEME_EXPORT_DIR:-$REPO_ROOT/output}}"

# Ensure konsave is installed
if ! command -v konsave >/dev/null 2>&1; then
    echo "Error: 'konsave' command not found. Please install konsave before running this script." >&2
    exit 1
fi

# Save the current KDE theme
if ! konsave -s "TL40-KDE-Backup"; then
    echo "Error: Failed to save KDE theme 'TL40-KDE-Backup' with konsave." >&2
    exit 1
fi

# Export the saved theme
if ! konsave -e "TL40-KDE-Backup" -n "$DATESTAMP-kde-bkp" -d "$EXPDIR" -f; then
    echo "Error: Failed to export KDE theme 'TL40-KDE-Backup' with konsave." >&2
    exit 1
fi
printf "\nKDE theme exported to %s/%s-kde-bkp.knsv\n" "$EXPDIR" "$DATESTAMP"