#!/usr/bin/env bash
#############################
# YubiKey-PAM Configuration
#############################
# CAUTION: pam-u2f must be installed beforehand (via base-tools.sh)
# If pam_u2f.so is missing, PAM will fail and lock you out of sudo/login

# Ensure script runs as root (required for PAM config and systemctl) by using 'sudo -u $SUDO_USER' to run pamu2fcfg as the actual user, preventing the YubiKey from being registered for root instead of your user.
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# Determine the actual user's home directory (not root's)
# SUDO_USER contains the original user when script is run via sudo
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
YK_DIR="$USER_HOME/.config/yubico"
KEY_FILE="$YK_DIR/u2f_keys"

# Create yubico config directory with proper ownership
printf "Setting up yubico directory...\n"
mkdir -p "$YK_DIR"
chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$YK_DIR"

# Register YubiKey for the user (not root)
# pamu2fcfg reads the YubiKey and creates a mapping: username:key_data
printf "Generating U2F key for user '${SUDO_USER:-$USER}'...\n"

# Check if pam-u2f is installed
if ! command -v pamu2fcfg &> /dev/null; then
    echo "ERROR: pam-u2f not found. Installing pam-u2f..."
    pacman -S --noconfirm pam-u2f || {
        echo "ERROR: Failed to install pam-u2f. Please install it manually: sudo pacman -S pam-u2f"
        exit 1
    }
fi

if [ ! -s "$KEY_FILE" ]; then
    # Run as actual user to ensure username in key file is correct
    sudo -u "${SUDO_USER:-$USER}" pamu2fcfg > "$KEY_FILE"
    chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$KEY_FILE"
    chmod 600 "$KEY_FILE"
    echo "✓ YubiKey registered for ${SUDO_USER:-$USER}"
else
    echo "✓ Existing registration found, skipping"
fi

# Update PAM configuration files to enable U2F authentication
# 'sufficient' means: if YubiKey auth succeeds, no password needed (but password still works as fallback)
# 'required' would mean: YubiKey is mandatory (dangerous - locks you out if YubiKey unavailable)
# 'cue' displays the cue_prompt message to user
printf "Configuring PAM files...\n"
PAM_LINE="auth sufficient pam_u2f.so authfile=$KEY_FILE cue cue_prompt=Tap YubiKey"
PAM_FILES=("/etc/pam.d/sudo" "/etc/pam.d/login" "/etc/pam.d/gdm-password" "/etc/pam.d/sshd" "/etc/pam.d/su" "/etc/pam.d/polkit-1" "/etc/pam.d/sddm" "/etc/pam.d/lightdm" "/etc/pam.d/common-auth" "/etc/pam.d/sddm-greeter" "/etc/pam.d/system-auth" "/etc/pam.d/system-login")

for file in "${PAM_FILES[@]}"; do
    [ ! -f "$file" ] && continue
    # Remove any existing pam_u2f lines to avoid duplicates
    sed -i '/^auth.*pam_u2f\.so/d' "$file"

    # Insert the U2F line as early as possible in the auth stack. Prefer after the header if present;
    # otherwise before the first auth line; fallback: prepend.
    if grep -q '^#%PAM-1.0' "$file"; then
        sed -i "/^#%PAM-1.0$/a ${PAM_LINE}" "$file"
    elif grep -q '^auth' "$file"; then
        sed -i "/^auth/ i ${PAM_LINE}" "$file"
    else
        sed -i "1i ${PAM_LINE}" "$file"
    fi

    echo "✓ Updated $file"
done

# Verify keyring integration in SDDM for auto-unlock
printf "\nVerifying keyring integration...\n"
if [ -f "/etc/pam.d/sddm" ]; then
    if ! grep -q "pam_gnome_keyring.so" /etc/pam.d/sddm; then
        echo "⚠ Warning: GNOME Keyring PAM module not found in /etc/pam.d/sddm"
        echo "   Keyrings may not auto-unlock on login. Consider adding pam_gnome_keyring.so"
    else
        echo "✓ Keyring auto-unlock configured"
    fi
fi

# Enable PC/SC Smart Card Daemon (required for YubiKey communication)
printf "Enabling pcscd service...\n"
systemctl enable --now pcscd
printf "Starting pcscd service...\n"
systemctl start --now pcscd
printf "\n✓ PC/SC Smart Card Daemon started successfully. Running test...\n"
sudo -K && sudo echo Test successful
##################################
# END: YubiKey-PAM Configuration #
##################################