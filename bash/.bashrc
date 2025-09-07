# ~/.bashrc managed by TL40-Dots stow package

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Prefer user's local bin
export PATH="$HOME/.local/bin:$PATH"

# Prompt and ls colors
export LS_COLORS="di=34:fi=0:ln=35"

# Load starship if available
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# User customizations (append-only) — edit this file in the repo
# ...existing code...
