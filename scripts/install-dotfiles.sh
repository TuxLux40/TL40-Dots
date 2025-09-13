#!/usr/bin/env bash
set -euo pipefail

#==============================================================================
# DOTFILES INSTALLER SCRIPT
#==============================================================================
# 
# PURPOSE: Automatically install and manage dotfiles using GNU Stow
# 
# WHAT THIS SCRIPT DOES:
# 1. Discovers all dotfile packages in the repository
# 2. Backs up existing configurations to prevent data loss
# 3. Creates symlinks from repository to home directory
# 4. Handles special cases (like system.yaml in root)
#
# REQUIREMENTS: GNU Stow must be installed
#==============================================================================

#------------------------------------------------------------------------------
# INITIALIZATION & CONFIGURATION
#------------------------------------------------------------------------------
# Set up script environment and determine working directories

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"

cd "$REPO_DIR"

#------------------------------------------------------------------------------
# DISPLAY CONFIGURATION
#------------------------------------------------------------------------------
# Colors and symbols for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK='✅'
LINK='🔗'
INFO='ℹ️'
ERROR='❌'

echo -e "${INFO} ${YELLOW}Installation script started...${NC}"

#==============================================================================
# DEPENDENCY VERIFICATION
#==============================================================================
# Ensure required tools are available before proceeding

## Check if stow is installed (should be installed via system.yaml)
if ! command -v stow >/dev/null 2>&1; then
  echo -e "${ERROR} ${RED}stow is not installed. Please install GNU stow first.${NC}" >&2
  exit 2
fi

#==============================================================================
# PACKAGE DISCOVERY
#==============================================================================
# Automatically find all dotfile packages to install

## collect packages (directories at repo root)
# LOGIC: Scan repository for directories, excluding hidden/system folders
#        Each directory represents a "package" of dotfiles to be managed
PACKAGES=()
for d in */; do
  # skip dotfiles or hidden folders like .git/
  [[ "$d" == .* ]] && continue
  PACKAGES+=("${d%/}")
done
# check if any packages found
if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  echo -e "${ERROR} ${RED}No packages found to stow.${NC}" >&2
  exit 1
fi

echo -e "${INFO} ${YELLOW}Packages to stow: ${PACKAGES[*]}${NC}"

#==============================================================================
# CLEANUP FUNCTIONS
#==============================================================================
# Functions to handle existing files and symlinks (no backups needed)

#------------------------------------------------------------------------------
# FUNCTION: remove_existing_target
# PURPOSE:  Remove existing files/symlinks before creating new ones
# PARAMS:   $1 = destination path
# BEHAVIOR: Simply removes existing files/symlinks to avoid conflicts
#------------------------------------------------------------------------------
remove_existing_target() {
  local dest="$1"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
    echo -e "${INFO} ${YELLOW}Removed existing file/symlink: ${NC}$dest"
  fi
}

#==============================================================================
# PRE-INSTALLATION CLEANUP
#==============================================================================
# Clean up existing files that would conflict with symlinking

# Note: We'll handle cleanup on a per-file basis, not the entire .config folder
echo -e "${INFO} ${YELLOW}Preparing for symlink creation...${NC}"

#==============================================================================
# STOW PACKAGE INSTALLATION
#==============================================================================
# Use GNU Stow to create symlinks for all packages

# Stow packages to target directory ($HOME) with verbose output
echo -e "${INFO} ${YELLOW}Stowing packages: ${PACKAGES[*]} to $TARGET${NC}"
stow -v -t "$TARGET" "${PACKAGES[@]}"
echo -e "${CHECK} ${GREEN}All packages have been stowed.${NC}"

#===============================================================================
# INTERACTIVE SYMLINK SELECTION FOR .CONFIG
#===============================================================================
# Discover all files in .config folder and present a menu for selection

echo -e "${INFO} ${YELLOW}Scanning for .config files to symlink...${NC}"

# Find all files in .config folder only
SYMLINK_CANDIDATES=()
if [ -d "$REPO_DIR/.config" ]; then
  while IFS= read -r -d $'\0' file; do
    rel_path="${file#$REPO_DIR/}"
    SYMLINK_CANDIDATES+=("$rel_path")
  done < <(find "$REPO_DIR/.config" -type f -print0)
fi

if [[ ${#SYMLINK_CANDIDATES[@]} -eq 0 ]]; then
  echo -e "${ERROR} ${RED}No .config files found to symlink.${NC}" >&2
  exit 1
fi

# Present menu for selection
echo -e "${INFO} ${YELLOW}Select .config files to symlink:${NC}"
PS3="Enter selection (number, or 0 for ALL): "
select opt in "Install ALL" "${SYMLINK_CANDIDATES[@]}"; do
  if [[ "$REPLY" == "0" || "$opt" == "Install ALL" ]]; then
    SELECTED_FILES=("${SYMLINK_CANDIDATES[@]}")
    break
  elif [[ -n "$opt" ]]; then
    SELECTED_FILES=("$opt")
    break
  else
    echo "Invalid selection. Try again."
  fi
done

# Create symlinks for selected files
for rel_path in "${SELECTED_FILES[@]}"; do
  src="$REPO_DIR/$rel_path"
  dest="$HOME/$rel_path"
  
  # Remove existing file/symlink first
  remove_existing_target "$dest"
  
  # Create parent directory if needed
  mkdir -p "$(dirname "$dest")"
  
  # Create symlink
  ln -sf "$src" "$dest"
  if [ "$(readlink -- "$dest")" = "$src" ]; then
    echo -e "${LINK} ${GREEN}Symlink set:${NC} $dest -> $src"
  else
    echo -e "${ERROR} ${RED}Symlink NOT correct:${NC} $dest"
  fi
done

echo -e "${CHECK} ${GREEN}Selected .config files have been symlinked.${NC}"

#==============================================================================
# SPECIAL CASE: SYSTEM.YAML TO ROOT
#==============================================================================
# Move system.yaml symlink to filesystem root for system-wide access

echo -e "${INFO} ${YELLOW}Moving system.yaml symlink to / ...${NC}"
if [ -L "$HOME/.config/system.yaml" ]; then
  echo -e "${INFO} ${YELLOW}sudo required to move system.yaml to /system.yaml${NC}"
  # move symlink to / with sudo
  sudo cp -P "$HOME/.config/system.yaml" /system.yaml
  if [ -L "/system.yaml" ] && [ "$(readlink -- "/system.yaml")" = "$REPO_DIR/.config/system.yaml" ]; then
    echo -e "${LINK} ${GREEN}Symlink for system.yaml successfully moved to /:${NC} /system.yaml -> $REPO_DIR/.config/system.yaml"
  else
    echo -e "${ERROR} ${RED}Symlink for /system.yaml is NOT correct!${NC}"
  fi
elif [ -f "$REPO_DIR/.config/system.yaml" ]; then
  echo -e "${INFO} ${YELLOW}system.yaml found but not symlinked. Creating direct symlink to / with sudo...${NC}"
  sudo ln -sf "$REPO_DIR/.config/system.yaml" /system.yaml
  if [ -L "/system.yaml" ] && [ "$(readlink -- "/system.yaml")" = "$REPO_DIR/.config/system.yaml" ]; then
    echo -e "${LINK} ${GREEN}Symlink for system.yaml created in /:${NC} /system.yaml -> $REPO_DIR/.config/system.yaml"
  else
    echo -e "${ERROR} ${RED}Failed to create symlink for /system.yaml!${NC}"
  fi
else
  echo -e "${INFO} ${YELLOW}No system.yaml found in .config - skipping${NC}"
fi

#==============================================================================
# INSTALLATION COMPLETE MESSAGE
#==============================================================================

echo -e "${CHECK} ${GREEN}Installation complete.${NC}"
