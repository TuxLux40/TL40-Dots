# Post-installation script to set up the environment
# To be installed after the main installation process of the system.yaml
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
sleep 2

# ------------------------------------------------------------------------------
# Add Yubikey authentication to PAM configuration for sudo, requiring touch and not prompting for password.
# This code sets up your Yubikey for sudo authentication.
# It adds a rule to the system's PAM configuration that lets you use your Yubikey's touch to confirm sudo commands instead of typing a password.
# This is safer than using "required" because "sufficient" means if the Yubikey works, you're in (no password needed), but if it fails (e.g., key lost), you can still use your password as a backup. "Required" would demand both, potentially locking you out if the key is unavailable.

# Backup existing PAM configuration for sudo
sudo tar -C / -czf ~/pam_u2f_backup.tgz etc/pam.d/sudo etc/u2f_mappings
echo -e "${INFO} ${GREEN}Backup of PAM configuration for sudo created at ~/pam_u2f_backup.tgz${NC}"

sleep 1

if ! grep -q "pam_u2f.so" /etc/pam.d/sudo; then
  echo -e "${INFO} ${YELLOW}Configuring PAM for Yubikey...${NC}"
  sudo bash -c 'echo "auth       sufficient   pam_u2f.so cue" >> /etc/pam.d/sudo'
  echo -e "${INFO} ${GREEN}PAM configured for Yubikey.${NC}"
else
  echo -e "${INFO} ${GREEN}PAM already configured for Yubikey. Skipping...${NC}"
fi
# Test sudo configuration and log output
echo -e "${INFO} ${YELLOW}Testing sudo configuration...${NC}"
bash ~/Projects/TL40-Dots/scripts/sudo_diag.sh | tee ~/sudo_diag.log
echo -e "${INFO} ${GREEN}Sudo configuration test completed. Log saved to ~/sudo_diag.log.${NC}"
# Note: If you encounter issues with sudo after this change, you can remove the last line from /etc/pam.d/sudo using:
# sudo sed -i '$ d' /etc/pam.d/sudo
# ------------------------------------------------------------------------------

sleep 2

# ------------------------------------------------------------------------------
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" # Install Homebrew
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc # Add Homebrew to bashrc for future sessions
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # Add Homebrew to current session
echo -e "${INFO} ${GREEN}Homebrew installed and configured.${NC}"
# ------------------------------------------------------------------------------

sleep 2

# ------------------------------------------------------------------------------
# Load iptables and iptable_nat modules at boot, ensuring that Winboat can function properly
# This is necessary for certain networking functionalities, such as NAT (Network Address Translation).
echo -e "ip_tables\niptable_nat" | sudo tee /etc/modules-load.d/iptables.conf

# ------------------------------------------------------------------------------
# Create symbolic links for dotfile in .config and system.yaml in root
ln -sf ~/Projects/TL40-Dots/config/atuin/config.toml ~/.config/atuin/config.toml # Link atuin config
cp ~/Projects/TL40-Dots/config/aichat/config.yaml ~/.config/aichat/config.yaml # Copy instead of symlinking to avoid exposing sensitive API keys and allow safe template editing
ln -sf ~/Projects/TL40-Dots/config/.bashrc ~/.bashrc # Link bashrc
ln -sf ~/Projects/TL40-Dots/pkg_lists/system.yaml ~/system.yaml # Link system.yaml to home directory
sudo mv ~/system.yaml / --force                                 # Move system.yaml symlink to root directory
echo -e "${INFO} ${GREEN}Symbolic links for .config and system.yaml created.${NC}" # Link creation message
# ------------------------------------------------------------------------------
sleep 2
# ------------------------------------------------------------------------------
# Restore GNOME Keyboard Shortcuts
# ------------------------------------------------------------------------------
echo -e "${INFO} ${YELLOW}Restoring GNOME keyboard shortcuts...${NC}"

# Define the list of custom keybinding paths
CUSTOM_KEYBINDINGS=(
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/'
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/'
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/'
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/'
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/'
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/'
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/'
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/'
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/'
)

# Set the custom keybindings list
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${CUSTOM_KEYBINDINGS[*]}"

# Define shortcuts data
declare -A SHORTCUTS
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']='name:Terminal|command:guake|binding:<Super>x'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']='name:Text Editor|command:flatpak run org.gnome.gitlab.cheywood.Buffer/x86_64/stable|binding:<Super>t'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']='name:VS Code|command:code|binding:<Super>c'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']='name:Yubikey Authenticator|command:yubico-authenticator|binding:<Super>y'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/']='name:Files|command:nautilus --new-window|binding:<Super>f'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/']='name:Ghostty|command:ghostty|binding:<Alt><Super>x'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/']='name:Signal|command:signal-desktop|binding:<Super>m'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/']='name:WhatsApp|command:flatpak run com.rtosta.zapzap|binding:<Alt><Super>m'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/']='name:Hardware Info|command:hardinfo2|binding:<Super>i'

# Apply each shortcut
for path in "${!SHORTCUTS[@]}"; do
    IFS='|' read -r name_part command_part binding_part <<< "${SHORTCUTS[$path]}"
    name_value="${name_part#*:}"
    command_value="${command_part#*:}"
    binding_value="${binding_part#*:}"
    
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$path" name "'$name_value'"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$path" command "'$command_value'"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$path" binding "'$binding_value'"
done

echo -e "${INFO} ${GREEN}GNOME keyboard shortcuts restored.${NC}"
# ------------------------------------------------------------------------------
sleep 2
# ------------------------------------------------------------------------------
# Final message
echo -e "${INFO} ${GREEN}Post-installation script completed.${NC}"
