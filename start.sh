#!/usr/bin/env bash
# TL40 Configurator entrypoint — top-level navigation only.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SCRIPTS_DIR="$REPO_ROOT/scripts"

export TL40_REPO_ROOT="$REPO_ROOT"
export TL40_SCRIPTS_DIR="$SCRIPTS_DIR"

# shellcheck source=scripts/lib/ui.sh
source "$SCRIPTS_DIR/lib/ui.sh"

usage() {
    cat <<'EOF'
TL40 Configurator

Usage: ./start.sh [options]

Options:
  -n, --dry-run   Show the commands that would run without executing them
  -h, --help      Display this help and exit
EOF
}

DRY_RUN=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

export TL40_DRY_RUN="$DRY_RUN"
DRY_ARGS=()
if (( DRY_RUN )); then
    DRY_ARGS=(--dry-run)
fi

tl40_pick_dialog

while true; do
    choice=$(tl40_menu_select "TL40 Configurator" "Select a section" \
        postinstall "Bootstrap TL40 on a new system" \
        dotfiles "Manage TL40 dotfiles and symlinks" \
        info "Export hardware/package/config reports" \
        packages "Install package managers and runtimes" \
        system "Desktop locale and shortcut helpers" \
        containers "Run container stacks and tooling" \
        fixes "Apply targeted fixes (OpenRGB, YubiKey, more)" \
        utilities "Service automation and helper scripts" \
        quit "Quit") || exit 0
    case "$choice" in
        postinstall)
            "$SCRIPTS_DIR/menu/postinstall.sh" "${DRY_ARGS[@]}"
            ;;
        dotfiles)
            "$SCRIPTS_DIR/menu/dotfiles.sh" "${DRY_ARGS[@]}"
            ;;
        info)
            "$SCRIPTS_DIR/menu/info.sh" "${DRY_ARGS[@]}"
            ;;
        packages)
            "$SCRIPTS_DIR/menu/packages.sh" "${DRY_ARGS[@]}"
            ;;
        system)
            "$SCRIPTS_DIR/menu/system.sh" "${DRY_ARGS[@]}"
            ;;
        containers)
            "$SCRIPTS_DIR/menu/containers.sh" "${DRY_ARGS[@]}"
            ;;
        fixes)
            "$SCRIPTS_DIR/menu/fixes.sh" "${DRY_ARGS[@]}"
            ;;
        utilities)
            "$SCRIPTS_DIR/menu/utilities.sh" "${DRY_ARGS[@]}"
            ;;
        quit)
            exit 0
            ;;
    esac
done
