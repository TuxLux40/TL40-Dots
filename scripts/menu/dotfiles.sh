#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

DOTFILES_SCRIPT="${TL40_SCRIPTS_DIR}/postinstall/dotfile-symlinks.sh"

show_help() {
    cat <<'EOF'
Dotfiles menu

Options:
  -n, --dry-run   Preview actions without executing
  -h, --help      Show this help
EOF
}

tl40_parse_common_args "$@"
if (( TL40_SHOW_HELP )); then
    show_help
    exit 0
fi

selective_link() {
    local options=()
    mapfile -t entries < <("$DOTFILES_SCRIPT" --list)
    if [[ ${#entries[@]} -eq 0 ]]; then
        tl40_msg_box "Dotfiles" "No dotfiles defined."
        return
    fi
    local entry
    for entry in "${entries[@]}"; do
        IFS='|' read -r key label <<<"$entry"
        options+=("$key" "$label" OFF)
    done
    local selection
    selection=$(tl40_checklist_select "Dotfiles" "Select items to link/copy" "${options[@]}") || return
    mapfile -t chosen <<<"$selection"
    if [[ ${#chosen[@]} -eq 0 ]]; then
        tl40_msg_box "Dotfiles" "Nothing selected."
        return
    fi
    run_dotfile_script "${chosen[@]}"
}

run_dotfile_script() {
    clear
    printf '== Dotfiles ==\n\n'
    tl40_run_repo_script "$DOTFILES_SCRIPT" "$@"
    printf '\nDone. Press Enter to return.'
    read -r _
}

while true; do
    choice=$(tl40_menu_select "Dotfiles" "Manage TL40 dotfiles" \
        selective "Select individual items" \
        all "Run full dotfile script" \
        back "Back") || exit 0
    case "$choice" in
        selective)
            selective_link
            ;;
        all)
            run_dotfile_script
            ;;
        back)
            exit 0
            ;;
    esac
done
