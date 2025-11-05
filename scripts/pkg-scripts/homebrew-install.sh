#!/usr/bin/env sh

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
      printf '%s %sHomebrew already installed. Skipping install step.%s\n' "${INFO}" "${GREEN}" "${NC}"
  else
      printf '%s %sInstalling Homebrew...%s\n' "${INFO}" "${YELLOW}" "${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        printf '%s %sHomebrew installation failed.%s\n' "${ERROR}" "${RED}" "${NC}"; return 1; }
  fi

  # Determine brew binary path (Linuxbrew default path fallback)
  if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
    elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
  else
      printf '%s %sbrew binary not found after install attempt.%s\n' "${ERROR}" "${RED}" "${NC}"; return 1
  fi

  # Bash integration
  if ! grep -q 'brew shellenv' ~/.bashrc 2>/dev/null; then
    printf 'eval "%s"\n' "$("${BREW_BIN}" shellenv)" >> "$HOME/.bashrc"
      printf '%s %sAdded brew shellenv to ~/.bashrc%s\n' "${INFO}" "${GREEN}" "${NC}"
  fi
  eval "$("${BREW_BIN}" shellenv)"

  # Fish integration
  mkdir -p ~/.config/fish
  FISH_CONFIG=~/.config/fish/config.fish
  if ! grep -q 'brew shellenv' "$FISH_CONFIG" 2>/dev/null; then
    # Use fish syntax eval ( ... )
      printf 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)\n' >> "$FISH_CONFIG"
      printf '%s %sAdded brew shellenv to fish config.%s\n' "${INFO}" "${GREEN}" "${NC}"
  fi

    printf '%s %sHomebrew ready (bash + fish).%s\n' "${INFO}" "${GREEN}" "${NC}"
}

  install_homebrew || printf '%s %sContinuing despite Homebrew issues.%s\n' "${ERROR}" "${RED}" "${NC}"