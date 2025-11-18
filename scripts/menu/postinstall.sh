#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

POSTINSTALL_STEPS=(
    "misc|Install miscellaneous tools|${TL40_SCRIPTS_DIR}/pkg-scripts/misc-tools.sh"
    "fastfetch|Install Fastfetch|${TL40_SCRIPTS_DIR}/pkg-scripts/fastfetch-install.sh"
    "atuin|Install Atuin sync|${TL40_SCRIPTS_DIR}/pkg-scripts/atuin-install.sh"
    "tailscale|Install Tailscale|${TL40_SCRIPTS_DIR}/pkg-scripts/tailscale-install.sh"
    "starship|Install Starship prompt|${TL40_SCRIPTS_DIR}/pkg-scripts/starship-install.sh"
    "homebrew|Install Homebrew|${TL40_SCRIPTS_DIR}/pkg-scripts/homebrew-install.sh"
    "dotfiles|Symlink dotfiles|${TL40_SCRIPTS_DIR}/postinstall/dotfile-symlinks.sh"
)

show_help() {
    cat <<'EOF'
Postinstall menu

Options:
  -n, --dry-run   Preview commands without running them
  -h, --help      Show this help
EOF
}

tl40_parse_common_args "$@"
if (( TL40_SHOW_HELP )); then
    show_help
    exit 0
fi

run_postinstall_sequence() {
    clear
    printf '== Guided TL40 postinstall ==\n\n'
    local entry key label path overall=0
    for entry in "${POSTINSTALL_STEPS[@]}"; do
        IFS='|' read -r key label path <<<"$entry"
        printf '-- %s --\n' "$label"
        if tl40_run_repo_script "$path"; then
            printf '  ✓ Done\n\n'
        else
            printf '  ✗ Failed (see logs above)\n\n'
            overall=1
        fi
    done
    printf 'Series finished. Press Enter to return.'
    read -r _
    return $overall
}

while true; do
    choice=$(tl40_menu_select "Postinstall" "Choose how to run TL40 postinstall" \
        full "Run full install.sh" \
        misc "Install miscellaneous tools" \
        steps "Guided step-by-step" \
        back "Back") || exit 0
    case "$choice" in
        full)
            tl40_run_in_shell "TL40 postinstall" "${TL40_REPO_ROOT}/install.sh"
            ;;
        misc)
            tl40_run_in_shell "Misc tools" "${TL40_SCRIPTS_DIR}/pkg-scripts/misc-tools.sh"
            ;;
        steps)
            run_postinstall_sequence
            ;;
        back)
            exit 0
            ;;
    esac
done
