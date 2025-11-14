#!/usr/bin/env bash
# Locale setup script - english language, german keyboard layout
set -euo pipefail
# Check if locale is already set to de_DE.UTF-8
if [[ "$(locale | grep '^LANG=' | cut -d= -f2)" == *en_US.UTF-8* ]]; then
    echo "Locale is already set to en_US.UTF-8. No changes made."
    exit 0
fi

# Generate and set the German locale
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
echo "Locale set to en_US.UTF-8 successfully."
# Inform the user to reboot for changes to take effect
echo "Please reboot your system for the changes to take effect."
exit 0