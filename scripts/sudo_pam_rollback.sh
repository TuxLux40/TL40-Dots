#!/usr/bin/env bash
# Sudo PAM Rollback Script - Restores previous PAM configuration for sudo
set -Eeuo pipefail
[ -f /etc/pam.d/sudo.bak.* ] && cp -a "$(ls -t /etc/pam.d/sudo.bak.* | head -1)" /etc/pam.d/sudo
sed -i '/pam_u2f\.so.*authfile=\/etc\/u2f_mappings/d' /etc/pam.d/sudo || true
echo "Rollback done."
