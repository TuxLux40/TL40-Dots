#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${TL40_DOTS_REPO:-https://github.com/TuxLux40/TL40-Dots.git}"
BRANCH="${TL40_DOTS_BRANCH:-main}"
TARGET_DIR_DEFAULT="${TL40_DOTS_DIR:-$HOME/Projects/TL40-Dots}"
TARGET_DIR="$TARGET_DIR_DEFAULT"
POSTINSTALL_ARGS=()

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [options] [-- <postinstall-args>]

Options:
  --dir PATH        Clone or update the repo at PATH (default: $HOME/Projects/TL40-Dots or TL40_DOTS_DIR)
  --branch NAME     Checkout NAME instead of the default branch
  --repo URL        Use an alternate Git remote for cloning
  -h, --help        Show this help message

All other arguments are forwarded to scripts/postinstall/postinstall.sh.
EOF
}

expand_path() {
    local input="$1"
    case "$input" in
        ~)
            printf '%s\n' "$HOME"
            ;;
        ~/*)
            printf '%s/%s\n' "$HOME" "${input#~/}"
            ;;
        /*)
            printf '%s\n' "$input"
            ;;
        *)
            printf '%s/%s\n' "$PWD" "$input"
            ;;
    esac
}

log() {
    printf '[bootstrap] %s\n' "$1"
}

error() {
    printf 'ERROR: %s\n' "$1" >&2
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "Missing required command: $1"
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --dir)
            if [[ $# -lt 2 ]]; then
                error "--dir requires a path"
                exit 1
            fi
            TARGET_DIR="$2"
            shift 2
            ;;
        --branch)
            if [[ $# -lt 2 ]]; then
                error "--branch requires a name"
                exit 1
            fi
            BRANCH="$2"
            shift 2
            ;;
        --repo)
            if [[ $# -lt 2 ]]; then
                error "--repo requires a URL"
                exit 1
            fi
            REPO_URL="$2"
            shift 2
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do
                POSTINSTALL_ARGS+=("$1")
                shift
            done
            break
            ;;
        *)
            POSTINSTALL_ARGS+=("$1")
            shift
            ;;
    esac
done

TARGET_DIR="$(expand_path "$TARGET_DIR")"

require_command git
require_command bash

log "Repository URL: $REPO_URL"
log "Target directory: $TARGET_DIR"
log "Branch: $BRANCH"

if [[ -d "$TARGET_DIR/.git" ]]; then
    log "Updating existing checkout"
    git -C "$TARGET_DIR" fetch --depth=1 origin "$BRANCH"
    git -C "$TARGET_DIR" checkout "$BRANCH"
    git -C "$TARGET_DIR" pull --ff-only origin "$BRANCH"
else
    if [[ -e "$TARGET_DIR" ]]; then
        if [[ -d "$TARGET_DIR" ]]; then
            if [[ -z "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
                rmdir "$TARGET_DIR"
            else
                error "Target directory exists and is not empty: $TARGET_DIR"
                exit 1
            fi
        else
            error "Target path exists and is not a directory: $TARGET_DIR"
            exit 1
        fi
    fi
    parent_dir="$(dirname "$TARGET_DIR")"
    mkdir -p "$parent_dir"
    log "Cloning repository"
    git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"
fi

log "Updating submodules (if any)"
git -C "$TARGET_DIR" submodule update --init --recursive

log "Running postinstall script"
bash "$TARGET_DIR/scripts/postinstall/postinstall.sh" "${POSTINSTALL_ARGS[@]}"

log "Bootstrap completed"
