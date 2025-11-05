#!/bin/bash
# dotfile-symlinks.sh — create/update symlinks for dotfiles on Linux (idempotent, XDG-aware).

set -Eeuo pipefail  # -E: trap functions, -e: exit on error, -u: undefined vars error, -o pipefail: fail on pipeline errors

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
