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
# 