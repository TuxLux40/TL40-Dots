#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

show_help() {
    cat <<'EOF'
Info export menu

Options:
  -n, --dry-run   Preview commands only
  -h, --help      Show this help
EOF
}

tl40_parse_common_args "$@"
if (( TL40_SHOW_HELP )); then
    show_help
    exit 0
fi

export_flatpaks() {
    if ! command -v flatpak >/dev/null 2>&1; then
        tl40_msg_box "Flatpaks" "flatpak CLI not found. Install Flatpak first."
        return
    fi
    tl40_run_in_shell "Export Flatpaks" "${TL40_SCRIPTS_DIR}/pkg-scripts/flatpaks-get-installed.sh"
}

export_arch_packages() {
    if ! command -v pacman >/dev/null 2>&1; then
        tl40_msg_box "pacman" "pacman not available on this system."
        return
    fi
    tl40_run_in_shell "Export pacman packages" "${TL40_SCRIPTS_DIR}/pkg-scripts/arch-pkgs-extract.sh"
}

while true; do
    choice=$(tl40_menu_select "Info exports" "Generate backup lists" \
        flatpaks "Export installed Flatpaks" \
        pacman "Export pacman packages" \
        back "Back") || exit 0
    case "$choice" in
        flatpaks) export_flatpaks ;;
        pacman) export_arch_packages ;;
        back) exit 0 ;;
    esac
done
