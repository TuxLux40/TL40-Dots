#!/usr/bin/env bash
set -euo pipefail

REPO_URL=${TL40_BOOTSTRAP_REPO:-"https://github.com/TuxLux40/TL40-Dots.git"}
TARGET_BASE=${TL40_BOOTSTRAP_DIR:-"$HOME/git"}
REPO_NAME=${TL40_BOOTSTRAP_NAME:-"TL40-Dots"}
TARGET_DIR="${TARGET_BASE}/${REPO_NAME}"
LAUNCHER_NAME=${TL40_BOOTSTRAP_CMD:-"tuxlux"}
LOCAL_BIN="$HOME/.local/bin"
FISH_CONF_D="$HOME/.config/fish/conf.d"
SKIP_LAUNCH=${TL40_BOOTSTRAP_NO_TUI:-0}

log() {
    printf '[tuxlux] %s\n' "$*"
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf '[tuxlux] Missing required command: %s\n' "$cmd" >&2
        exit 1
    fi
}

ensure_repos() {
    mkdir -p "$TARGET_BASE"
    if [[ -d "$TARGET_DIR/.git" ]]; then
        log "Updating existing clone at $TARGET_DIR"
        git -C "$TARGET_DIR" fetch --tags --prune
        git -C "$TARGET_DIR" pull --ff-only
    else
        log "Cloning TL40-Dots into $TARGET_DIR"
        git clone "$REPO_URL" "$TARGET_DIR"
    fi
}

ensure_local_bin_on_path() {
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        export PATH="$LOCAL_BIN:$PATH"
    fi

    local marker='TL40 bootstrap PATH helper'
    local profile="$HOME/.profile"
    if [[ ! -f $profile ]]; then
        touch "$profile"
    fi
    if ! grep -q "$marker" "$profile" 2>/dev/null; then
        cat >>"$profile" <<'EOF'
# >>> TL40 bootstrap PATH helper >>>
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi
export PATH
# <<< TL40 bootstrap PATH helper <<<
EOF
    fi

    if command -v fish >/dev/null 2>&1 || [[ -d "$HOME/.config/fish" ]]; then
        mkdir -p "$FISH_CONF_D"
        local fish_snippet="$FISH_CONF_D/tl40-path.fish"
        if [[ ! -f $fish_snippet ]]; then
            cat >"$fish_snippet" <<'EOF'
# Added by TL40 bootstrap PATH helper
if not contains $HOME/.local/bin $PATH
    set -x PATH $HOME/.local/bin $PATH
end
EOF
        fi
    fi
}

install_launcher() {
    mkdir -p "$LOCAL_BIN"
    local launcher_path="$LOCAL_BIN/$LAUNCHER_NAME"
    cat >"$launcher_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="${TL40_LAUNCHER_REPO:-__TL40_REPO_DIR__}"
if [[ ! -d "$REPO_DIR" ]]; then
    echo "TL40-Dots repo not found at $REPO_DIR" >&2
    exit 1
fi
exec "$REPO_DIR/start.sh" "$@"
EOF
    perl -0pi -e 's#__TL40_REPO_DIR__#'"$TARGET_DIR"'#g' "$launcher_path"
    chmod +x "$launcher_path"

    if [[ -w /usr/local/bin ]]; then
        ln -sf "$launcher_path" "/usr/local/bin/$LAUNCHER_NAME"
        log "Linked launcher to /usr/local/bin/$LAUNCHER_NAME"
    else
        ensure_local_bin_on_path
        log "Launcher installed at $launcher_path"
    fi
}

launch_tui() {
    if [[ "$SKIP_LAUNCH" != "0" ]]; then
        log "TL40 Configurator launch skipped by TL40_BOOTSTRAP_NO_TUI"
        return
    fi
    log "Starting TL40 Configurator"
    exec "$TARGET_DIR/start.sh"
}

main() {
    require_cmd git
    ensure_repos
    install_launcher
    launch_tui
}

main "$@"
