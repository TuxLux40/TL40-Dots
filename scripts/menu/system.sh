#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

show_help() {
    cat <<'EOF'
System setup menu

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

configure_locale_keyboard_de() {
    tl40_run_in_shell "Locale + keyboard" bash -c 'set -euo pipefail
if ! command -v localectl >/dev/null 2>&1; then
    echo "localectl is not available on this system."
    exit 1
fi
sudo localectl set-locale LANG=de_DE.UTF-8
sudo localectl set-x11-keymap de
localectl status'
}

while true; do
    choice=$(tl40_menu_select "System setup" "Desktop/system helpers" \
        locale "Set locale + keyboard (de_DE)" \
        gnome_backup "Backup GNOME shortcuts" \
        gnome_restore "Restore GNOME shortcuts" \
        kde_backup "Export KDE shortcuts" \
        back "Back") || exit 0
    case "$choice" in
        locale) configure_locale_keyboard_de ;;
        gnome_backup) tl40_run_in_shell "GNOME shortcut backup" "${TL40_SCRIPTS_DIR}/gnome/list_gnome_shortcuts.sh" ;;
        gnome_restore) tl40_run_in_shell "GNOME shortcut restore" "${TL40_SCRIPTS_DIR}/gnome/restore-gnome-shortcuts.sh" ;;
        kde_backup) tl40_run_in_shell "KDE shortcut export" "${TL40_SCRIPTS_DIR}/kde/kde-shortcuts-export.sh" ;;
        back) exit 0 ;;
    esac
done
