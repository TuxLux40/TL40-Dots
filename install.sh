#!/usr/bin/env bash
set -euo pipefail

# Simple installer that stows the available packages into $HOME

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"

cd "$REPO_DIR"

if ! command -v stow >/dev/null 2>&1; then
  echo "stow is not installed. Please install GNU stow first." >&2
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
  echo "No packages found to stow." >&2
  exit 1
fi

echo "Stowing packages: ${PACKAGES[*]} to $TARGET"
stow -v -t "$TARGET" "${PACKAGES[@]}"

echo "Done."
echo "Fixing starship.toml symlink..."
ln -sf "$REPO_DIR/.config/starship/.config/starship.toml" "$HOME/.config/starship.toml"
echo "Symlink for starship.toml gesetzt: $HOME/.config/starship.toml -> $REPO_DIR/.config/starship/.config/starship.toml"
