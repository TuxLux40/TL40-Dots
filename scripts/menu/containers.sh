#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

TL40_COMPOSE_CMD=()

show_help() {
    cat <<'EOF'
Container stack menu

Options:
  -n, --dry-run   Preview compose commands
  -h, --help      Show this help
EOF
}

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

tl40_parse_common_args "$@"
if (( TL40_SHOW_HELP )); then
    show_help
    exit 0
fi

friendly_stack_label() {
    local compose_path="$1"
    local slug=${compose_path#"${TL40_CONFIG_DIR}/containers/"}
    slug=${slug%%/*}
    case "$slug" in
        calibre) echo "Calibre" ;;
        calibre-web) echo "Calibre Web" ;;
        checkmk) echo "Checkmk" ;;
        glance) echo "Glance" ;;
        ittools) echo "IT Tools" ;;
        kleopatra) echo "Kleopatra" ;;
        lazydocker) echo "Lazydocker" ;;
        lazylibrarian) echo "LazyLibrarian" ;;
        n8n) echo "n8n" ;;
        openwebui) echo "Open WebUI" ;;
        paperless-ngx) echo "Paperless NGX" ;;
        portainer) echo "Portainer" ;;
        snipeit) echo "Snipe-IT" ;;
        vaultwarden) echo "Vaultwarden" ;;
        vscode-server) echo "VS Code Server" ;;
        windows) echo "Windows VM" ;;
        *) printf '%s' "${slug//-/ }" | awk '{for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' ;;
    esac
}

ensure_compose() {
    if [[ ${#TL40_COMPOSE_CMD[@]} -gt 0 ]]; then
        return 0
    fi
    if command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
        TL40_COMPOSE_CMD=(podman compose)
        return 0
    fi
    if command -v podman-compose >/dev/null 2>&1; then
        TL40_COMPOSE_CMD=(podman-compose)
        return 0
    fi
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        TL40_COMPOSE_CMD=(docker compose)
        return 0
    fi
    if command -v docker-compose >/dev/null 2>&1; then
        TL40_COMPOSE_CMD=(docker-compose)
        return 0
    fi
    tl40_msg_box "Containers" 'Neither "podman compose" nor "docker compose" is available.'
    return 1
}

run_compose_action() {
    local compose_file="$1" action="$2"
    ensure_compose || return
    local stack_dir
    stack_dir=$(dirname "$compose_file")
    clear
    printf '== %s (%s) ==\n\n' "$action" "$stack_dir"
    if (( TL40_DRY_RUN )); then
        case "$action" in
            up)
                printf '[dry-run] Would run: %s\n' "$(tl40_format_command "${TL40_COMPOSE_CMD[@]}" -f "$compose_file" up -d)"
                printf '[dry-run] Would list services with: %s\n' "$(tl40_format_command "${TL40_COMPOSE_CMD[@]}" -f "$compose_file" ps)"
                ;;
            down)
                printf '[dry-run] Would run: %s\n' "$(tl40_format_command "${TL40_COMPOSE_CMD[@]}" -f "$compose_file" down)"
                ;;
        esac
        printf '\nPress Enter to continue.'
        read -r _
        return 0
    fi
    pushd "$stack_dir" >/dev/null
    set +e
    case "$action" in
        up) "${TL40_COMPOSE_CMD[@]}" -f "$compose_file" up -d ;;
        down) "${TL40_COMPOSE_CMD[@]}" -f "$compose_file" down ;;
    esac
    local status=$?
    if [[ $status -eq 0 && $action == up ]]; then
        printf '\nActive services/ports:\n\n'
        "${TL40_COMPOSE_CMD[@]}" -f "$compose_file" ps
    fi
    set -e
    popd >/dev/null
    printf '\nCommand exited with status %s. Press Enter to continue.' "$status"
    read -r _
    return $status
}

container_action_menu() {
    local compose_file="$1" label="$2" choice
    while true; do
        choice=$(tl40_menu_select "Container" "$label" \
            up "Bring stack up (detached)" \
            down "Stop and remove stack" \
            back "Back") || return
        case "$choice" in
            up|down) run_compose_action "$compose_file" "$choice" ;;
            back) return ;;
        esac
    done
}

main_menu() {
    while true; do
        mapfile -t stacks < <(find "${TL40_CONFIG_DIR}/containers" -mindepth 1 -maxdepth 2 -type f \( -name 'compose.yaml' -o -name 'compose.yml' -o -name 'docker-compose.yml' \) | sort)
        if [[ ${#stacks[@]} -eq 0 ]]; then
            tl40_msg_box "Containers" "No compose files under config/containers."
            return 0
        fi
        local options=(manage "Manage containers with lazydocker (installs if missing)")
        local idx=1
        local file
        for file in "${stacks[@]}"; do
            local friendly
            friendly=$(friendly_stack_label "$file")
            local compose_name
            compose_name=$(basename "$file")
            local label="$friendly"
            if [[ $compose_name != "compose.yaml" ]]; then
                label+=" (${compose_name})"
            fi
            options+=("$idx" "$label")
            ((idx++))
        done
        options+=("back" "Back")
        local selection
        selection=$(tl40_menu_select "Container stacks" "Start or stop stacks, or open lazydocker" "${options[@]}") || return 0
        if [[ $selection == "back" ]]; then
            return 0
        fi
        if [[ $selection == "manage" ]]; then
            launch_lazydocker
            continue
        fi
        local numeric
        numeric=$((selection))
        local chosen="${stacks[numeric-1]}"
        container_action_menu "$chosen" "$(friendly_stack_label "$chosen")"
    done
}

main_menu
