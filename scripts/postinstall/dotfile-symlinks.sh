#!/usr/bin/env bash
# Symlink dotfiles from repo to XDG config directories. When sourced, exposes
# helper functions for the TUI; when executed directly, syncs all entries.

set -euo pipefail

if [[ -z ${TL40_DOTFILES_REG_LOADED:-} ]]; then
    TL40_DOTFILES_REG_LOADED=1

    REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

    DOTFILE_ITEMS=(
        "atuin|link|${REPO_ROOT}/config/atuin/config.toml|${XDG_CONFIG_HOME}/atuin/config.toml|Atuin history config"
        "aichat|copy|${REPO_ROOT}/config/aichat/config.yaml|${XDG_CONFIG_HOME}/aichat/config.yaml|AIChat config (copy)"
        "bashrc|link|${REPO_ROOT}/config/.bashrc|${HOME}/.bashrc|Bash RC"
        "starship|link|${REPO_ROOT}/config/starship.toml|${XDG_CONFIG_HOME}/starship.toml|Starship prompt"
        "fastfetch|link|${REPO_ROOT}/config/fastfetch|${XDG_CONFIG_HOME}/fastfetch|Fastfetch profiles"
        "ghostty|link|${REPO_ROOT}/config/ghostty/config|${XDG_CONFIG_HOME}/ghostty/config|Ghostty terminal"
        "fish|link|${REPO_ROOT}/config/fish/config.fish|${XDG_CONFIG_HOME}/fish/config.fish|Fish shell config"
    )

    link_config() {
        local src="$1" dest="$2"
        mkdir -p "$(dirname "$dest")"
        rm -rf "$dest"
        ln -s "$src" "$dest"
        printf 'Linked: %s -> %s\n' "$dest" "$src"
    }

    copy_config() {
        local src="$1" dest="$2"
        mkdir -p "$(dirname "$dest")"
        cp -af "$src" "$dest"
        printf 'Copied: %s -> %s\n' "$src" "$dest"
    }

    dotfiles_apply_entry() {
        local mode="$1" src="$2" dest="$3" label="$4"
        [[ -e $src ]] || { printf 'Missing source: %s\n' "$src" >&2; return 1; }
        case "$mode" in
            link) link_config "$src" "$dest" ;;
            copy) copy_config "$src" "$dest" ;;
            *) printf 'Unknown mode %s for %s\n' "$mode" "$label" >&2; return 1 ;;
        esac
        printf '  -> %s synced to %s\n' "$label" "$dest"
    }

    dotfiles_apply_by_key() {
        local key="$1" entry
        for entry in "${DOTFILE_ITEMS[@]}"; do
            IFS='|' read -r item mode src dest label <<<"$entry"
            if [[ $item == "$key" ]]; then
                dotfiles_apply_entry "$mode" "$src" "$dest" "$label"
                return 0
            fi
        done
        printf 'Unknown dotfile key: %s\n' "$key" >&2
        return 1
    }

    dotfiles_apply_all() {
        local entry mode src dest label
        for entry in "${DOTFILE_ITEMS[@]}"; do
            IFS='|' read -r _ mode src dest label <<<"$entry"
            dotfiles_apply_entry "$mode" "$src" "$dest" "$label"
        done
    }

    dotfiles_list_entries() {
        local entry
        for entry in "${DOTFILE_ITEMS[@]}"; do
            IFS='|' read -r key _ _ _ label <<<"$entry"
            printf '%s|%s\n' "$key" "$label"
        done
    }
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --help)
                cat <<'EOF'
Usage: dotfile-symlinks.sh [options] [keys...]

Options:
  --list        Print available dotfile keys and exit
  --help        Show this help

With no keys, all dotfiles are synced. Provide one or more keys to target
specific entries.
EOF
                exit 0
                ;;
            --list)
                dotfiles_list_entries
                exit 0
                ;;
        esac
    fi

    if [[ $# -gt 0 ]]; then
        for key in "$@"; do
            dotfiles_apply_by_key "$key"
        done
    else
        dotfiles_apply_all
        echo "All dotfiles symlinked successfully"
    fi
fi
