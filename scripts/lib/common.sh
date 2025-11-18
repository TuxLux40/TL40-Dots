# Common variables shared across TL40 scripts.

if [[ -n ${TL40_LIB_COMMON:-} ]]; then
    return
fi

TL40_LIB_COMMON=1

TL40_LIB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TL40_SCRIPTS_DIR=${TL40_SCRIPTS_DIR:-$(cd "${TL40_LIB_DIR}/.." && pwd)}
TL40_REPO_ROOT=${TL40_REPO_ROOT:-$(cd "${TL40_SCRIPTS_DIR}/.." && pwd)}
TL40_CONFIG_DIR=${TL40_CONFIG_DIR:-"${TL40_REPO_ROOT}/config"}
TL40_XDG_CONFIG_HOME=${TL40_XDG_CONFIG_HOME:-"${XDG_CONFIG_HOME:-$HOME/.config}"}
TL40_MENU_LINES=${TL40_MENU_LINES:-20}
TL40_MENU_WIDTH=${TL40_MENU_WIDTH:-78}
TL40_MENU_HEIGHT=${TL40_MENU_HEIGHT:-10}
TL40_DRY_RUN=${TL40_DRY_RUN:-0}
TL40_DIALOG_BIN=${TL40_DIALOG_BIN:-""}

if [[ -z ${TL40_OS_DETECTED:-} && -f "${TL40_SCRIPTS_DIR}/detect-os.sh" ]]; then
    # shellcheck disable=SC1090
    source "${TL40_SCRIPTS_DIR}/detect-os.sh" >/dev/null 2>&1 || true
    TL40_OS_DETECTED=1
fi

tl40_parse_common_args() {
    TL40_SHOW_HELP=0
    TL40_REMAINING_ARGS=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                TL40_DRY_RUN=1
                ;;
            -h|--help)
                TL40_SHOW_HELP=1
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    TL40_REMAINING_ARGS=("$@")
}
