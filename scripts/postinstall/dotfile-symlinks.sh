#!/usr/bin/env bash
# dotfile-symlinks.sh — create/update symlinks for dotfiles on Linux (idempotent, XDG-aware).

set -Eeuo pipefail  # -E: trap functions, -e: exit on error, -u: undefined vars error, -o pipefail: fail on pipeline errors

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

INFO='[dotfiles]'

# Flags
DRY_RUN=false
FORCE=false

print_usage() {
	cat <<'USAGE'
Usage: dotfile-symlinks.sh [options]

Options:
  -n, --dry-run   Show actions without applying any changes
  -f, --force     Overwrite/replace existing destination files or directories
  -h, --help      Show this help

Behavior:
  • Without --force, existing destinations that don't already point to the source are skipped with a warning.
  • With --force, existing files/dirs/links are removed before linking/copying.
USAGE
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		-n|--dry-run) DRY_RUN=true; shift ;;
		-f|--force)   FORCE=true;   shift ;;
		-h|--help)    print_usage; exit 0 ;;
		*) break ;;
	esac
done

run_cmd() {
	# Echo the command, and only execute it when not a dry-run
	if $DRY_RUN; then
		printf '%s DRY-RUN: %s\n' "$INFO" "$*"
	else
		eval "$@"
	fi
}

ensure_dir() {
	local dir="$1"
	run_cmd mkdir -p "$dir"
}

dest_points_to_src() {
	# returns 0 (true) if $2 is a symlink targeting $1 (same realpath), else 1
	local src="$1" dest="$2"
	[[ -L "$dest" ]] || return 1
	# Use realpath if available to normalize; fall back to readlink comparison
	if command -v realpath >/dev/null 2>&1; then
		local src_real dest_target_real
		src_real="$(realpath -m "$src" 2>/dev/null || true)"
		dest_target_real="$(realpath -m "$(readlink "$dest")" 2>/dev/null || true)"
		[[ -n "$src_real" && -n "$dest_target_real" && "$src_real" == "$dest_target_real" ]]
	else
		[[ "$(readlink "$dest")" == "$src" ]]
	fi
}

ensure_dir_and_link() {
	local src="$1"
	local dest="$2"

	if [[ ! -e "$src" ]]; then
		printf '%s missing source: %s\n' "$INFO" "$src"
		return 1
	fi

	ensure_dir "$(dirname "$dest")"

	if dest_points_to_src "$src" "$dest"; then
		printf '%s skip: up-to-date link %s -> %s\n' "$INFO" "$dest" "$src"
		return 0
	fi

	if [[ -e "$dest" || -L "$dest" ]]; then
		if $FORCE; then
			printf '%s replace: %s (existing) -> %s\n' "$INFO" "$dest" "$src"
			run_cmd rm -rf "$dest"
		else
			printf '%s warn: %s exists; use --force to overwrite\n' "$INFO" "$dest"
			return 0
		fi
	else
		printf '%s link: %s -> %s\n' "$INFO" "$dest" "$src"
	fi

	run_cmd ln -s "$src" "$dest"
}

ensure_dir_and_copy() {
	local src="$1"
	local dest="$2"

	if [[ ! -e "$src" ]]; then
		printf '%s missing source: %s\n' "$INFO" "$src"
		return 1
	fi

	ensure_dir "$(dirname "$dest")"

	if [[ -e "$dest" && !$FORCE ]]; then
		printf '%s warn: %s exists; use --force to overwrite\n' "$INFO" "$dest"
		return 0
	fi

	if $FORCE && [[ -e "$dest" || -L "$dest" ]]; then
		printf '%s replace: %s (existing) with %s\n' "$INFO" "$dest" "$src"
	else
		printf '%s copy: %s -> %s\n' "$INFO" "$src" "$dest"
	fi

	run_cmd cp -a "$src" "$dest"
}

# Dotfiles and app configs (edit/add mappings below)
ensure_dir_and_link   "$REPO_ROOT/config/atuin/config.toml"   "$XDG_CONFIG_HOME/atuin/config.toml"   # Link atuin config
ensure_dir_and_copy   "$REPO_ROOT/config/aichat/config.yaml"  "$XDG_CONFIG_HOME/aichat/config.yaml"  # Copy aichat
ensure_dir_and_link   "$REPO_ROOT/config/.bashrc"             "$HOME/.bashrc"                        # Link bashrc
# ensure_dir_and_link   "$REPO_ROOT/pkg_lists/system.yaml"       "$HOME/system.yaml"                    # Link system.yaml to home directory (BlendOS only)
ensure_dir_and_link   "$REPO_ROOT/config/starship.toml"       "$XDG_CONFIG_HOME/starship.toml"       # Link starship config
ensure_dir_and_link   "$REPO_ROOT/config/fastfetch"           "$XDG_CONFIG_HOME/fastfetch"           # Link fastfetch directory
ensure_dir_and_link   "$REPO_ROOT/config/ghostty/config"      "$XDG_CONFIG_HOME/ghostty/config"      # Link ghostty config file
ensure_dir_and_link   "$REPO_ROOT/config/fish/config.fish"    "$XDG_CONFIG_HOME/fish/config.fish"    # Link fish config
