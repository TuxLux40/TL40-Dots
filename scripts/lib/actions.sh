# Common action helpers (command execution, file ops).

if [[ -n ${TL40_LIB_ACTIONS:-} ]]; then
    return
fi

TL40_LIB_ACTIONS=1

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# shellcheck source=./ui.sh
source "${TL40_SCRIPTS_DIR}/lib/ui.sh"

tl40_format_command() {
    local out="" arg
    for arg in "$@"; do
        if [[ -z $out ]]; then
            printf -v out '%q' "$arg"
        else
            printf -v out '%s %q' "$out" "$arg"
        fi
    done
    printf '%s' "$out"
}

tl40_run_in_shell() {
    local title="$1"
    shift
    clear
    printf '== %s ==\n\n' "$title"
    if (( TL40_DRY_RUN )); then
        printf '[dry-run] Would run: %s\n' "$(tl40_format_command "$@")"
        printf '\nPress Enter to continue.'
        read -r _
        return 0
    fi
    set +e
    "$@"
    local status=$?
    set -e
    printf '\nCommand exited with status %s. Press Enter to continue.' "$status"
    read -r _
    return $status
}

tl40_run_repo_script() {
    local script_path="$1"
    shift || true
    if [[ ! -f $script_path ]]; then
        printf 'Missing script: %s\n' "$script_path" >&2
        return 1
    fi
    if (( TL40_DRY_RUN )); then
        printf '[dry-run] Would execute %s' "$script_path"
        if [[ $# -gt 0 ]]; then
            printf ' %s' "$(tl40_format_command "$@")"
        fi
        printf '\n'
        return 0
    fi
    if [[ ! -x $script_path ]]; then
        chmod +x "$script_path"
    fi
    "$script_path" "$@"
}

tl40_link_entry() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    if (( TL40_DRY_RUN )); then
        printf '[dry-run] Would link %s -> %s\n' "$dest" "$src"
        return 0
    fi
    ln -s "$src" "$dest"
}

tl40_copy_entry() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if (( TL40_DRY_RUN )); then
        printf '[dry-run] Would copy %s -> %s\n' "$src" "$dest"
        return 0
    fi
    cp -a "$src" "$dest"
}
