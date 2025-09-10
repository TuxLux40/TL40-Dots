#!/usr/bin/env bash
set -euo pipefail

# Simple installer that stows the available packages into $HOME

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"

cd "$REPO_DIR"

# Farben und Symbole
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK='✅'
LINK='🔗'
INFO='ℹ️'
ERROR='❌'

if ! command -v stow >/dev/null 2>&1; then
  echo -e "${ERROR} ${RED}stow ist nicht installiert. Bitte zuerst GNU stow installieren.${NC}" >&2
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
  echo -e "${ERROR} ${RED}Keine Pakete zum Stowen gefunden.${NC}" >&2
  exit 1
fi

echo "Stowing packages: ${PACKAGES[*]} to $TARGET"
echo "Done."
echo -e "${INFO} ${YELLOW}Stowing Pakete: ${PACKAGES[*]} nach $TARGET${NC}"
stow -v -t "$TARGET" "${PACKAGES[@]}"
echo -e "${CHECK} ${GREEN}Alle Pakete wurden gestowed.${NC}"

echo -e "${INFO} ${YELLOW}Symlinks werden gesetzt ...${NC}"
# Starship.toml Symlink
ln -sf "$REPO_DIR/.config/starship/.config/starship.toml" "$HOME/.config/starship.toml"
if [ "$(readlink -- "$HOME/.config/starship.toml")" = "$REPO_DIR/.config/starship/.config/starship.toml" ]; then
  echo -e "${LINK} ${GREEN}Symlink für starship.toml korrekt gesetzt:${NC} $HOME/.config/starship.toml -> $REPO_DIR/.config/starship/.config/starship.toml"
else
  echo -e "${ERROR} ${RED}Symlink für starship.toml ist NICHT korrekt!${NC}"
fi
# system.yaml Symlink
ln -sf "$REPO_DIR/system.yaml" "$HOME/system.yaml"
if [ "$(readlink -- "$HOME/system.yaml")" = "$REPO_DIR/system.yaml" ]; then
  echo -e "${LINK} ${GREEN}Symlink für system.yaml korrekt gesetzt:${NC} $HOME/system.yaml -> $REPO_DIR/system.yaml"
else
  echo -e "${ERROR} ${RED}Symlink für system.yaml ist NICHT korrekt!${NC}"
fi
echo -e "${CHECK} ${GREEN}Installation abgeschlossen.${NC}"
