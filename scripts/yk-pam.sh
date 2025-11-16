#!/usr/bin/env bash
#############################
# YubiKey-PAM Configuration
#############################

# Check if running as root, if not, restart with sudo
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# Setup Yubico Folder in Home Directory
printf "Creating Yubico config directory...\n"
mkdir -p ~/.config/yubico
printf "Yubico config directory created at ~/.config/yubico\n"

# Add security key auth file
printf "Generating U2F keys configuration file...\n"
pamu2fcfg > ~/.config/yubico/u2f_keys
printf "U2F keys configuration file created at ~/.config/yubico/u2f_keys\n"

# Add the following line as the first 'auth' line in each file:
# auth sufficient pam_u2f.so cue [cue_prompt=Tap YubiKey]
# Add this line to the relevant PAM configuration files below:
#   /etc/pam.d/login         – For console logins
#   /etc/pam.d/sudo          – For sudo authentication
#   /etc/pam.d/gdm-password  – For GNOME authentication
#   /etc/pam.d/sshd          – SSH authentication against a local OpenSSH Server

printf "Writing PAM configuration lines to appropriate files...\n"
PAM_LINE="auth sufficient pam_u2f.so cue [cue_prompt=Tap YubiKey]"
PAM_FILES=("/etc/pam.d/login" "/etc/pam.d/sudo" "/etc/pam.d/gdm-password" "/etc/pam.d/sshd")

for file in "${PAM_FILES[@]}"; do
    if [ -f "$file" ]; then
        # Insert the line at the top of the file (idempotent)
        if grep -qF "$PAM_LINE" "$file"; then
            echo "PAM line already present in $file, skipping"
        else
            sed -i "1i ${PAM_LINE}" "$file"
            echo "Added PAM line to $file (at top)"
        fi
    else
        echo "File $file not found, skipping"
    fi
done
printf "PAM configuration complete.\n"
##################################
# END: YubiKey-PAM Configuration #
##################################