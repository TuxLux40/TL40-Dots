#!/usr/bin/env bash
set -euo pipefail

# Installer that stows the available packages into $HOME

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"

cd "$REPO_DIR"

# Colors and Symbols
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK='✅'
LINK='🔗'
INFO='ℹ️'
ERROR='❌'

echo -e "${INFO} ${YELLOW}Installation script started...${NC}"

if ! command -v stow >/dev/null 2>&1; then
  echo -e "${ERROR} ${RED}stow is not installed. Please install GNU stow first.${NC}" >&2
  exit 2
fi

# collect packages (directories at repo root)
PACKAGES=()
for d in */; do
  # skip dotfiles or hidden folders like .git/
  [[ "$d" == .* ]] && continue
  PACKAGES+=("${d%/}")
done

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  echo -e "${ERROR} ${RED}No packages found to stow.${NC}" >&2
  exit 1
fi

echo -e "${INFO} ${YELLOW}Packages to stow: ${PACKAGES[*]}${NC}"

# Function: remove existing symlinks or backup existing files before stow
remove_or_backup_target() {
  local src="$1"
  local dest="$2"
  if [ -L "$dest" ]; then
    # if it already points to the repo source, remove it so stow can manage
    if [ "$(readlink -- "$dest")" = "$src" ]; then
      rm -f "$dest"
      echo -e "${INFO} ${YELLOW}Removing existing symlink: ${NC}$dest -> $src"
    else
      echo -e "${ERROR} ${RED}Existing symlink $dest does not point to $src, leaving it in place.${NC}"
    fi
  elif [ -e "$dest" ]; then
    # backup regular files/directories
    local bak="${dest}.backup.$(date +%s)"
    mv "$dest" "$bak"
    echo -e "${INFO} ${YELLOW}Backup existing file: ${NC}$dest -> $bak"
  fi
}

# Pre-clean targets that stow will try to manage (files in package roots)
for pkg in "${PACKAGES[@]}"; do
  pkgdir="$REPO_DIR/$pkg"
  if [ -d "$pkgdir" ]; then
    while IFS= read -r -d $'\0' file; do
      # only consider regular files in the package root (not .config nested dirs here)
      if [ -f "$file" ]; then
        dest="$TARGET/$(basename "$file")"
        remove_or_backup_target "$file" "$dest"
      fi
    done < <(find "$pkgdir" -maxdepth 1 -type f -print0)
  fi
done

echo -e "${INFO} ${YELLOW}Stowing packages: ${PACKAGES[*]} to $TARGET${NC}"
stow -v -t "$TARGET" "${PACKAGES[@]}"
echo -e "${CHECK} ${GREEN}All packages have been stowed.${NC}"

echo -e "${INFO} ${YELLOW}Symlinks are being set...${NC}"

# ensure ~/.config exists
mkdir -p "$HOME/.config"

# Helper: set a symlink and print a consistent status message (German)
set_and_check_symlink() {
  local src="$1"
  local dest="$2"
  local label="${3:-$(basename "$dest") }"
  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  if [ "$(readlink -- "$dest")" = "$src" ]; then
    echo -e "${LINK} ${GREEN}Symlink for ${label} set:${NC} $dest -> $src"
  else
    echo -e "${ERROR} ${RED}Symlink for ${label} NOT correct:${NC} $dest"
  fi
}

declare -A SYMLINKS=(
  ["$REPO_DIR/.config/starship/.config/starship.toml"]="$HOME/.config/starship.toml"
  ["$REPO_DIR/system.yaml"]="$HOME/system.yaml"
  ["$REPO_DIR/bash/.bashrc"]="$HOME/.bashrc"
  ["$REPO_DIR/git/.gitconfig"]="$HOME/.gitconfig"
  ["$REPO_DIR/.config/kitty/kitty.conf"]="$HOME/.config/kitty/kitty.conf"
  ["$REPO_DIR/.config/guake/session.json"]="$HOME/.config/guake/session.json"
  ["$REPO_DIR/.config/aichat/config.yaml"]="$HOME/.config/aichat/config.yaml"
  ["$REPO_DIR/.config/atuin/config.toml"]="$HOME/.config/atuin/config.toml"
  ["$REPO_DIR/.config/burn-my-windows/profiles/1755598388870831.conf"]="$HOME/.config/burn-my-windows/profiles/1755598388870831.conf"
  ["$REPO_DIR/.config/gSnap/layouts.json"]="$HOME/.config/gSnap/layouts.json"
  ["$REPO_DIR/.config/user-dirs.dirs"]="$HOME/.config/user-dirs.dirs"
  ["$REPO_DIR/fav_themes"]="$HOME/fav_themes"
  ["$REPO_DIR/README.md"]="$HOME/README.md"
)

for src in "${!SYMLINKS[@]}"; do
  dest="${SYMLINKS[$src]}"
  # use the basename of the source file as a readable label
  set_and_check_symlink "$src" "$dest" "$(basename "$src")"
done

echo -e "${INFO} ${YELLOW}Moving system.yaml symlink to / ...${NC}"
if [ -L "$HOME/system.yaml" ]; then
  # move symlink to / with sudo
  sudo mv -f "$HOME/system.yaml" /system.yaml
  if [ -L "/system.yaml" ] && [ "$(readlink -- "/system.yaml")" = "$REPO_DIR/system.yaml" ]; then
    echo -e "${LINK} ${GREEN}Symlink for system.yaml successfully moved to /:${NC} /system.yaml -> $REPO_DIR/system.yaml"
  else
    echo -e "${ERROR} ${RED}Symlink for /system.yaml is NOT correct!${NC}"
  fi
else
  echo -e "${ERROR} ${RED}No symlink $HOME/system.yaml found to move!${NC}"
fi

echo -e "${CHECK} ${GREEN}Installation complete.${NC}"
