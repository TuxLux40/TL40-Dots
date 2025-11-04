#!/usr/bin/env bash
# dotfile-symlinks.sh — create/update symlinks for dotfiles on Linux (idempotent, XDG-aware).

set -Eeuo pipefail  # -E: trap functions, -e: exit on error, -u: undefined vars error, -o pipefail: fail on pipeline errors

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

INFO='[dotfiles]'

ensure_dir() {
	local dir="$1"
	mkdir -p "$dir"
}

ensure_dir_and_link() {
	local src="$1"
	local dest="$2"

	if [[ ! -e "$src" ]]; then
		printf '%s missing source: %s\n' "$INFO" "$src"
		return 1
	fi

	ensure_dir "$(dirname "$dest")"

	if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
		return 0
	fi

	if [[ -e "$dest" || -L "$dest" ]]; then
		rm -rf "$dest"
	fi

	ln -s "$src" "$dest"
	printf '%s linked %s -> %s\n' "$INFO" "$dest" "$src"
}

ensure_dir_and_copy() {
	local src="$1"
	local dest="$2"

	if [[ ! -e "$src" ]]; then
		printf '%s missing source: %s\n' "$INFO" "$src"
		return 1
	fi

	ensure_dir "$(dirname "$dest")"
	cp -a "$src" "$dest"
	printf '%s copied %s -> %s\n' "$INFO" "$src" "$dest"
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
