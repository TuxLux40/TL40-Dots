#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

show_help() {
    cat <<'EOF'
Fixes and tweaks menu

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
        tl40_msg_box "Fixes" "Not found: $script_path"
        return
    fi
    tl40_run_in_shell "$label" "$script_path"
}

while true; do
    choice=$(tl40_menu_select "Fixes & tweaks" "Apply targeted fixes" \
        openrgb "Install OpenRGB udev rules so USB devices are detected" \
        tailscale "Reset DNS settings after Tailscale overwrites them" \
        yk "Configure sudo to require a YubiKey via PAM U2F" \
        rpi "Force Raspberry Pi HDMI output via KMS overrides" \
        back "Back") || exit 0
    case "$choice" in
        openrgb) run_helper "openrgb-udev-install.sh" "Install OpenRGB udev rules" ;;
        tailscale) run_helper "fixes/tailscale-dns-fix.sh" "Reset Tailscale DNS" ;;
        yk) run_helper "yk-pam.sh" "Configure sudo + YubiKey" ;;
        rpi) run_helper "fixes/rpi-hdmi-fix.sh" "Force Raspberry Pi HDMI" ;;
        back) exit 0 ;;
    esac
done
