#!/usr/bin/env bash
#############################
# YubiKey-PAM Configuration
#############################
# CAUTION: pam-u2f must be installed beforehand (via base-tools.sh)
# If pam_u2f.so is missing, PAM will fail and lock you out of sudo/login!

# Ensure script runs as root (required for PAM config and systemctl)
# This script uses 'sudo -u $SUDO_USER' to run pamu2fcfg as the actual user,
# preventing the YubiKey from being registered for root instead of your user.
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
# 'sufficient' means: if YubiKey auth succeeds, no password needed
# 'cue' displays the cue_prompt message to user
printf "Configuring PAM files...\n"
PAM_LINE="auth sufficient pam_u2f.so authfile=$KEY_FILE cue cue_prompt=Tap YubiKey"
PAM_FILES=("/etc/pam.d/sudo" "/etc/pam.d/login" "/etc/pam.d/gdm-password" "/etc/pam.d/sshd")

for file in "${PAM_FILES[@]}"; do
    [ ! -f "$file" ] && continue
    # Remove any existing pam_u2f lines to avoid duplicates
    sed -i '/^auth.*pam_u2f\.so/d' "$file"
    # Insert auth line right after PAM header
    sed -i "/^#%PAM-1.0$/a ${PAM_LINE}" "$file"
    echo "✓ Updated $file"
done

# Enable PC/SC Smart Card Daemon (required for YubiKey communication)
printf "Enabling pcscd service...\n"
systemctl enable --now pcscd
systemctl restart pcscd
printf "\n✓ YubiKey PAM authentication configured successfully!\n"
printf "Test with: sudo -K && sudo echo test\n"
##################################
# END: YubiKey-PAM Configuration #
##################################