#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

show_help() {
        cat <<'EOF'
Utility helper menu

Options:
    -n, --dry-run   Preview helper scripts
    -h, --help      Show this help
EOF
}

tl40_parse_common_args "$@"
if (( TL40_SHOW_HELP )); then
    show_help
    exit 0
fi

run_helper() {
    local rel="$1" label="$2"
    local script_path="${TL40_SCRIPTS_DIR}/${rel}"
    if [[ ! -f $script_path ]]; then
        tl40_msg_box "Scripts" "Not found: $script_path"
        return
    fi
    tl40_run_in_shell "$label" "$script_path"
}

while true; do
    choice=$(tl40_menu_select "Utility scripts" "Service units and helper automation" \
        inprem "Create and enable the Input Remapper user service" \
        pvpn "Deploy the ProtonVPN WireGuard systemd unit" \
        nas "Create NAS directory symlinks from config/system.yaml" \
        back "Back") || exit 0
    case "$choice" in
        inprem) run_helper "inprem-sdunit.sh" "Configure Input Remapper systemd unit" ;;
        pvpn) run_helper "pvpn-sdunit.sh" "Configure ProtonVPN systemd unit" ;;
        nas) run_helper "nas-symlinks.sh" "Create NAS symlinks" ;;
        back) exit 0 ;;
    esac
done
