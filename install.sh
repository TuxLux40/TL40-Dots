#! /bin/sh -e

# Dotfiles bootstrap.
#
# Standalone  (curl | sh)  : clones repo to $DOTFILES_DIR then stows.
# In-repo    (./install.sh) : stows from current checkout.
# Linutil-compat            : leaves dotfiles/ layout untouched so linutil's
#                             built-in dotfiles-setup.sh works against a clone.

REPO_URL="${DOTFILES_REPO:-https://github.com/TuxLux40/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# --- helpers --------------------------------------------------------------
RC='\033[0m'; RED='\033[31m'; YELLOW='\033[33m'; CYAN='\033[36m'; GREEN='\033[32m'

msg()  { printf "%b\n" "${CYAN}==>${RC} $*"; }
warn() { printf "%b\n" "${YELLOW}warn:${RC} $*" >&2; }
die()  { printf "%b\n" "${RED}error:${RC} $*" >&2; exit 1; }

command_exists() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Detect privilege-escalation tool (sudo / doas). Root gets a no-op.
if [ "$(id -u)" = "0" ]; then
    ESCALATION_TOOL="env"
else
    ESCALATION_TOOL=""
    for _tool in sudo doas; do
        if command_exists "$_tool"; then
            ESCALATION_TOOL="$_tool"
            break
        fi
    done
    [ -z "$ESCALATION_TOOL" ] && die "no supported escalation tool (sudo/doas)"
fi

# Detect package manager (same probe order as linutil).
PACKAGER=""
for _pm in nala apt-get dnf pacman zypper apk xbps-install eopkg; do
    if command_exists "$_pm"; then
        PACKAGER="$_pm"
        break
    fi
done
[ -z "$PACKAGER" ] && die "no supported package manager"

# --- pkg installers -------------------------------------------------------
pkg_install() {
    # $1 = binary to check, $2.. = package name(s) per pm
    _bin="$1"; shift
    command_exists "$_bin" && return 0
    msg "installing $_bin"
    case "$PACKAGER" in
        pacman)       $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm "$@" ;;
        apt-get|nala) $ESCALATION_TOOL "$PACKAGER" install -y "$@" ;;
        dnf)          $ESCALATION_TOOL "$PACKAGER" install -y "$@" ;;
        zypper)       $ESCALATION_TOOL "$PACKAGER" install -y "$@" ;;
        apk)          $ESCALATION_TOOL "$PACKAGER" add "$@" ;;
        xbps-install) $ESCALATION_TOOL "$PACKAGER" -Sy "$@" ;;
        eopkg)        $ESCALATION_TOOL "$PACKAGER" install -y "$@" ;;
        *)            $ESCALATION_TOOL "$PACKAGER" install -y "$@" ;;
    esac
}

# --- args -----------------------------------------------------------------
WITH_CLAMAV=0
WITH_SFTP=0
WITH_NAS=0
NAS_PATH=""
DRY_RUN=0
ADOPT=0

usage() {
    cat <<EOF
Usage: install.sh [options]

  --dry-run     Preview stow actions (stow -n), install nothing.
  --adopt       Adopt existing local configs INTO the repo (local wins,
                repo gets dirty with local versions). Default: repo wins —
                local files replaced with repo versions.
  --clamav      Also stow clamav package to /etc/clamav (needs root).
  --sftp        Run sftp-setup.sh after stowing.
  --nas [PATH]  Run symlink-nas.sh after stowing (optional NAS root).
  -h, --help    Show this message.

Env:
  DOTFILES_REPO  Git URL (default: $REPO_URL)
  DOTFILES_DIR   Clone target if running via curl | sh (default: \$HOME/.dotfiles)
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --adopt)   ADOPT=1;   shift ;;
        --clamav)  WITH_CLAMAV=1; shift ;;
        --sftp)    WITH_SFTP=1;   shift ;;
        --nas)
            WITH_NAS=1; shift
            # Optional path arg (skip if next token is another flag or absent).
            case "${1:-}" in
                ""|-*) ;;
                *) NAS_PATH="$1"; shift ;;
            esac
            ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown arg: $1 (try --help)" ;;
    esac
done

# --- locate repo ----------------------------------------------------------
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE:-}" ]; then
    SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$BASH_SOURCE")" && pwd)"
elif [ -f "$0" ] && [ "$0" != "sh" ] && [ "$0" != "-sh" ]; then
    SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd 2>/dev/null)" || SCRIPT_DIR=""
fi

REPO_ROOT=""
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/dotfiles" ]; then
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "./dotfiles" ] && [ -f "./install.sh" ]; then
    REPO_ROOT="$(pwd)"
fi

if [ -z "$REPO_ROOT" ]; then
    # curl | sh mode: clone.
    pkg_install git git
    if [ -d "$DOTFILES_DIR/.git" ]; then
        msg "updating existing clone at $DOTFILES_DIR"
        git -C "$DOTFILES_DIR" pull --ff-only
    elif [ -e "$DOTFILES_DIR" ]; then
        die "$DOTFILES_DIR exists and is not a git checkout"
    else
        msg "cloning $REPO_URL -> $DOTFILES_DIR"
        git clone --depth=1 "$REPO_URL" "$DOTFILES_DIR"
    fi
    REPO_ROOT="$DOTFILES_DIR"
fi

[ -d "$REPO_ROOT/dotfiles" ] || die "no dotfiles/ dir under $REPO_ROOT"

# --- install stow (first, before anything else touches $HOME) -------------
pkg_install stow stow

# --- stow ------------------------------------------------------------------
# Always pass --adopt so stow never chokes on pre-existing real files. With
# default mode we git-restore the repo afterwards so adopted content is
# discarded and symlinks resolve to the repo's tracked versions (repo wins).
# With --adopt we skip the restore, leaving the adopted local files in the
# repo working tree for the user to review/commit (local wins).
STOW_FLAGS="-v --adopt"
[ "$DRY_RUN" -eq 1 ] && STOW_FLAGS="$STOW_FLAGS -n"

# In default (repo-wins) mode, stow --adopt can't absorb pre-existing
# symlinks that point elsewhere (e.g. another dotfiles repo) — it aborts
# with "not owned by stow". Pre-remove those symlinks so stow proceeds.
# Real files are left alone; --adopt handles them and git restore discards
# the adopted content afterwards.
clean_foreign_symlinks() {
    _pkg_dir="$1"; _target_root="$2"; _sudo="$3"
    [ -d "$_pkg_dir" ] || return 0
    find "$_pkg_dir" \( -type f -o -type l \) -print | while IFS= read -r _f; do
        _rel="${_f#"$_pkg_dir"/}"
        _t="$_target_root/$_rel"
        if [ -L "$_t" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                msg "would unlink foreign symlink: $_t"
            else
                $_sudo rm -f "$_t"
            fi
        fi
    done
}

msg "stowing packages from $REPO_ROOT/dotfiles -> $HOME"
cd "$REPO_ROOT/dotfiles"

for _pkg in */; do
    _pkg="${_pkg%/}"
    case "$_pkg" in
        clamav) continue ;;   # handled below (root target)
    esac
    [ -d "$_pkg" ] || continue
    printf "%b\n" "${CYAN}--${RC} $_pkg"
    [ "$ADOPT" -eq 0 ] && clean_foreign_symlinks "$_pkg" "$HOME" ""
    # shellcheck disable=SC2086
    stow $STOW_FLAGS -t "$HOME" "$_pkg" || warn "stow failed for $_pkg"
done

if [ "$WITH_CLAMAV" -eq 1 ] && [ -d "clamav" ]; then
    msg "stowing clamav -> /etc"
    [ "$ADOPT" -eq 0 ] && clean_foreign_symlinks "clamav" "/etc" "$ESCALATION_TOOL"
    # shellcheck disable=SC2086
    $ESCALATION_TOOL stow $STOW_FLAGS -t /etc clamav || warn "stow failed for clamav"
fi

cd - >/dev/null

# Default (no --adopt): repo is source of truth. Discard anything stow
# adopted so every symlink resolves to the tracked repo version.
if [ "$ADOPT" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    if [ -d "$REPO_ROOT/.git" ]; then
        msg "restoring repo (local versions discarded, repo is source of truth)"
        git -C "$REPO_ROOT" restore dotfiles/ 2>/dev/null || \
            git -C "$REPO_ROOT" checkout -- dotfiles/ 2>/dev/null || \
            warn "git restore failed — symlinks may point to adopted local content"
        [ "$WITH_CLAMAV" -eq 1 ] && git -C "$REPO_ROOT" restore dotfiles/clamav 2>/dev/null || true
    else
        warn "$REPO_ROOT is not a git checkout; cannot restore repo versions"
    fi
fi

# --- opt-in extras --------------------------------------------------------
if [ "$WITH_SFTP" -eq 1 ]; then
    msg "running sftp-setup.sh"
    sh "$REPO_ROOT/sftp-setup.sh"
fi

if [ "$WITH_NAS" -eq 1 ]; then
    msg "running symlink-nas.sh"
    _nas_args=""
    [ "$DRY_RUN" -eq 1 ] && _nas_args="--dry-run"
    [ -n "$NAS_PATH" ] && _nas_args="$_nas_args --nas $NAS_PATH"
    # shellcheck disable=SC2086
    bash "$REPO_ROOT/symlink-nas.sh" $_nas_args
fi

printf "%b\n" "${GREEN}done.${RC}"
