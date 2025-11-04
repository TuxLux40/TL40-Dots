#!/bin/bash
# dotfile-symlinks.sh — create/update symlinks for dotfiles on Linux (idempotent, XDG-aware).

set -Eeuo pipefail  # -E: trap functions, -e: exit on error, -u: undefined vars error, -o pipefail: fail on pipeline errors

# Resolve repo root even when script is invoked from arbitrary working directories
SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if REPO_ROOT_GIT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null); then
	REPO_ROOT="$REPO_ROOT_GIT"
else
	REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
fi

# Prefer XDG config dir; fallback to ~/.config
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Pretty output (colors + icons). Auto-disabled if stdout isn't a TTY or NO_COLOR is set.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	C_RESET='\033[0m'
	C_GREEN='\033[32m'
	C_YELLOW='\033[33m'
	C_BLUE='\033[34m'
	C_MAGENTA='\033[35m'
	C_CYAN='\033[36m'
	C_DIM='\033[2m'
else
	C_RESET=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_MAGENTA=''; C_CYAN=''; C_DIM=''
fi

# Log helpers
ok()    { printf "%b✔%b %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf "%b⚠%b %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
info()  { printf "%bℹ%b %s\n" "$C_BLUE" "$C_RESET" "$*"; }
skip()  { printf "%b⏭%b %s\n" "$C_DIM" "$C_RESET" "$*"; }
actL()  { printf "%b🔗%b %s\n" "$C_CYAN" "$C_RESET" "$*"; }
actC()  { printf "%b📄%b %s\n" "$C_CYAN" "$C_RESET" "$*"; }
actD()  { printf "%b📁%b %s\n" "$C_CYAN" "$C_RESET" "$*"; }
drymsg(){ printf "%b🧪 DRY-RUN%b %s\n" "$C_MAGENTA" "$C_RESET" "$*"; }

# Args: support --dry-run and --help
DRY_RUN=false
for arg in "$@"; do
	case "$arg" in
		-n|--dry-run)
			DRY_RUN=true ;;
			-h|--help)
						# Keep help minimal; full details live in docs/dotfile-symlinks.md
						printf '%s\n' \
					"Usage: $(basename "$0") [--dry-run]" \
					"  --dry-run, -n   Show actions without executing" \
					"  NO_COLOR=1      Disable colored output"
				exit 0 ;;
	esac
done

		log() { printf '%s\n' "$*"; }
		run() { if $DRY_RUN; then return 0; else "$@"; fi; }   # Execute unless in dry-run mode

canon() { readlink -f -- "$1" 2>/dev/null || printf '%s' "$1"; } # Canonicalize path for equality checks

# Link helper: ensure parent dir exists and create/update symlink.
# ln -sfn (GNU ln):
#   -s   symbolic link
#   -f   replace existing destination
#   -n   do not dereference if dest is a symlink to a directory
ensure_dir_and_link() {
	local SRC="$1" DST="$2"
	# Warn if source missing, but still allow creating a dangling link if desired
		if [ ! -e "$SRC" ]; then
			warn "source does not exist: $SRC"
	fi
		actD "ensure dir: $(dirname "$DST")"
		run mkdir -p "$(dirname "$DST")"
	if [ -e "$DST" ] || [ -L "$DST" ]; then
		local RS RC
		RS=$(canon "$SRC") || RS="$SRC"
		RC=$(canon "$DST") || RC="$DST"
		if [ "$RS" = "$RC" ]; then
				skip "already up-to-date: $DST -> $SRC"
			return 0
		fi
	fi
		actL "link: $DST -> $SRC"
		run ln -sfn "$SRC" "$DST"
}

# Copy helper: ensure parent dir exists; copy only if source is newer (-u)
ensure_dir_and_copy() {
	local SRC="$1" DST="$2"
		if [ ! -e "$SRC" ]; then
			skip "source missing, cannot copy: $SRC"
		return 0
	fi
		actD "ensure dir: $(dirname "$DST")"
		run mkdir -p "$(dirname "$DST")"
	# If source and destination resolve to the same file, skip to avoid cp error
	local RS RC
	RS=$(canon "$SRC") || RS="$SRC"
	RC=$(canon "$DST") || RC="$DST"
	if [ "$RS" = "$RC" ]; then
			skip "source and destination are the same: $DST"
		return 0
	fi
		# Copy only if newer or missing
		actC "copy: $SRC -> $DST (if newer)"
		run cp -u "$SRC" "$DST"
}

# Dotfiles and app configs (edit/add mappings below)
ensure_dir_and_link   "$REPO_ROOT/config/atuin/config.toml"   "$XDG_CONFIG_HOME/atuin/config.toml"   # Link atuin config
ensure_dir_and_copy   "$REPO_ROOT/config/aichat/config.yaml"  "$XDG_CONFIG_HOME/aichat/config.yaml"  # Copy aichat
ensure_dir_and_link   "$REPO_ROOT/config/.bashrc"             "$HOME/.bashrc"                        # Link bashrc
# ensure_dir_and_link   "$REPO_ROOT/pkg_lists/system.yaml"       "$HOME/system.yaml"                    # Link system.yaml to home directory (BlendOS only)
ensure_dir_and_link   "$REPO_ROOT/config/starship.toml"       "$XDG_CONFIG_HOME/starship.toml"       # Link starship config
ensure_dir_and_link   "$REPO_ROOT/config/fastfetch"           "$XDG_CONFIG_HOME/fastfetch"           # Link fastfetch directory
ensure_dir_and_link   "$REPO_ROOT/config/ghostty/config"      "$XDG_CONFIG_HOME/ghostty/config"      # Link ghostty config file
ensure_dir_and_link   "$REPO_ROOT/config/fish/config.fish"  "$XDG_CONFIG_HOME/fish/config.fish"    # Link fish config
ensure_dir_and_link   "$REPO_ROOT/config/micro/settings.json" "$XDG_CONFIG_HOME/micro/settings.json" # Link micro editor settings

if $DRY_RUN; then
	drymsg "Completed dry-run. No changes were made."
else
	ok "Completed linking/copying."
fi