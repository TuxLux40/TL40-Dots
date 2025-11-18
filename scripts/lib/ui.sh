# Shared UI helpers (dialog/whiptail wrappers).

if [[ -n ${TL40_LIB_UI:-} ]]; then
    return
fi

TL40_LIB_UI=1

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

tl40_pick_dialog() {
    if [[ -n $TL40_DIALOG_BIN ]]; then
        return
    fi
    if command -v whiptail >/dev/null 2>&1; then
        TL40_DIALOG_BIN="whiptail"
    elif command -v dialog >/dev/null 2>&1; then
        TL40_DIALOG_BIN="dialog"
    else
        printf 'Install "whiptail" or "dialog" to use this menu.\n' >&2
        exit 1
    fi
}

tl40_menu_select() {
    local title="$1" text="$2"
    shift 2
    local selection status
    tl40_pick_dialog
    set +e
    selection=$($TL40_DIALOG_BIN --clear --title "$title" --menu "$text" "$TL40_MENU_LINES" "$TL40_MENU_WIDTH" "$TL40_MENU_HEIGHT" "$@" 3>&1 1>&2 2>&3)
    status=$?
    set -e
    [[ $status -eq 0 ]] || return 1
    printf '%s' "$selection"
}

tl40_checklist_select() {
    local title="$1" text="$2"
    shift 2
    local selection status
    tl40_pick_dialog
    set +e
    selection=$($TL40_DIALOG_BIN --clear --separate-output --title "$title" --checklist "$text" "$TL40_MENU_LINES" "$TL40_MENU_WIDTH" "$TL40_MENU_HEIGHT" "$@" 3>&1 1>&2 2>&3)
    status=$?
    set -e
    [[ $status -eq 0 ]] || return 1
    printf '%s' "$selection"
}

tl40_msg_box() {
    tl40_pick_dialog
    $TL40_DIALOG_BIN --clear --title "$1" --msgbox "$2" 10 70
}

tl40_confirm_box() {
    tl40_pick_dialog
    $TL40_DIALOG_BIN --clear --title "$1" --yesno "$2" 10 70
}
