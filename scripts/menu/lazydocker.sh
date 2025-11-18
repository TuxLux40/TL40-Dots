#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

show_help() {
    cat <<'EOF'
Launch lazydocker helper

Options:
  -n, --dry-run   Preview install/launch steps
  -h, --help      Show this help
EOF
}

tl40_parse_common_args "$@"
if (( TL40_SHOW_HELP )); then
    show_help
    exit 0
fi

install_lazydocker() {
    if command -v lazydocker >/dev/null 2>&1; then
        tl40_msg_box "lazydocker" "lazydocker already installed."
        return 0
    fi
    if command -v brew >/dev/null 2>&1; then
        tl40_run_in_shell "Install lazydocker (brew)" brew install jesseduffield/lazydocker/lazydocker
        return 0
    fi
    if [[ "${PKG_MANAGER:-}" == "pacman" ]] && command -v paru >/dev/null 2>&1; then
        tl40_run_in_shell "Install lazydocker (paru)" paru -S --needed lazydocker
        return 0
    fi
    if command -v go >/dev/null 2>&1; then
        tl40_run_in_shell "Install lazydocker (go install)" bash -c "set -euo pipefail
go install github.com/jesseduffield/lazydocker@latest
echo 'Ensure $HOME/go/bin is on PATH.'"
        return 0
    fi
    tl40_msg_box "lazydocker" "No supported installer detected. Install manually from https://github.com/jesseduffield/lazydocker."
    return 1
}

launch_lazydocker() {
    if ! command -v lazydocker >/dev/null 2>&1; then
        if tl40_confirm_box "lazydocker" "lazydocker is not installed. Install it now?"; then
            install_lazydocker || return
        else
            return
        fi
    fi
    if command -v lazydocker >/dev/null 2>&1; then
        tl40_run_in_shell "lazydocker" lazydocker
    else
        tl40_msg_box "lazydocker" "Installation failed or binary not on PATH."
    fi
}

launch_lazydocker
