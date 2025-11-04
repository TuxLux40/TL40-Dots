install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo -e "${INFO} ${GREEN}Homebrew already installed. Skipping install step.${NC}"
  else
    echo -e "${INFO} ${YELLOW}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      echo -e "${ERROR} ${RED}Homebrew installation failed.${NC}"; return 1; }
  fi

  # Determine brew binary path (Linuxbrew default path fallback)
  if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
  else
    echo -e "${ERROR} ${RED}brew binary not found after install attempt.${NC}"; return 1
  fi

  # Bash integration
  if ! grep -q 'brew shellenv' ~/.bashrc 2>/dev/null; then
    echo "eval \"$(${BREW_BIN} shellenv)\"" >> ~/.bashrc
    echo -e "${INFO} ${GREEN}Added brew shellenv to ~/.bashrc${NC}"
  fi
  eval "$("${BREW_BIN}" shellenv)"

  # Fish integration
  mkdir -p ~/.config/fish
  FISH_CONFIG=~/.config/fish/config.fish
  if ! grep -q 'brew shellenv' "$FISH_CONFIG" 2>/dev/null; then
    # Use fish syntax eval ( ... )
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> "$FISH_CONFIG"
    echo -e "${INFO} ${GREEN}Added brew shellenv to fish config.${NC}"
  fi

  echo -e "${INFO} ${GREEN}Homebrew ready (bash + fish).${NC}"
}

install_homebrew || echo -e "${ERROR} ${RED}Continuing despite Homebrew issues.${NC}"