# Post-installation script to set up the environment
# To be installed after the main installation process
# Only for OS/DE independent programs and configurations
# See other scripts for OS/DE specific setups
# Work in progress - use at your own risk

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

##########################################################################
# START: Install Homebrew (idempotent) and configure shells (bash + fish)#
##########################################################################
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
########################################################################
# END: Install Homebrew (idempotent) and configure shells (bash + fish)#
########################################################################

sleep 2

##########################################################################
# START: Load iptables and iptable_nat modules at boot, ensuring that Winboat can function properly #
##########################################################################
# This is necessary for certain networking functionalities, such as NAT (Network Address Translation).
echo -e "ip_tables\niptable_nat" | sudo tee /etc/modules-load.d/iptables.conf
##########################################################################
# END: Load iptables and iptable_nat modules at boot, ensuring that Winboat can function properly #
##########################################################################

sleep 1

##########################################################################
# START: Create symbolic links for dotfile in .config and system.yaml in root #
##############################################################################
ensure_dir_and_link() { mkdir -p "$(dirname "$2")" && ln -sf "$1" "$2"; }
ensure_dir_and_copy() { mkdir -p "$(dirname "$2")" && cp "$1" "$2"; }

ensure_dir_and_link   ~/Projects/TL40-Dots/config/atuin/config.toml ~/.config/atuin/config.toml   # Link atuin config
ensure_dir_and_copy   ~/Projects/TL40-Dots/config/aichat/config.yaml ~/.config/aichat/config.yaml # Copy aichat
ensure_dir_and_link   ~/Projects/TL40-Dots/config/.bashrc            ~/.bashrc                    # Link bashrc
ensure_dir_and_link   ~/Projects/TL40-Dots/pkg_lists/system.yaml     ~/system.yaml                # Link system.yaml to home directory
ensure_dir_and_link   ~/Projects/TL40-Dots/config/starship.toml      ~/.config/starship.toml      # Link starship config
ensure_dir_and_link   ~/Projects/TL40-Dots/config/fastfetch          ~/.config/fastfetch          # Link fastfetch directory
ensure_dir_and_link   ~/Projects/TL40-Dots/config/ghostty/config     ~/.config/ghostty/config     # Link ghostty config file
echo -e "${INFO} ${GREEN}Symbolic links created.${NC}" # Link creation message
############################################################################
# END: Create symbolic links for dotfile in .config and system.yaml in root#
############################################################################

# Final message
echo -e "${INFO} ${GREEN}Post-installation script completed.${NC}"
