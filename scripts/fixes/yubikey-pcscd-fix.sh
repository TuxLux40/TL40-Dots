#!/usr/bin/env bash
#############################
# YubiKey pcscd Fix
#############################
# Fixes: LIBUSB_ERROR_BUSY crashes when pcscd tries to start
# Root Cause: yubico-authenticator (FIDO2 GUI) blocks YubiKey CCID interface
# Note: pam-u2f (sudo auth) does NOT cause this - it's a local PAM module
# Solution: Create higher-priority udev rule for CCID access

if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

printf "🔧 Installing YubiKey pcscd udev rules...\n"

# Create udev rule for YubiKey CCID support
# Priority 55 is higher than libfido2's 60, so this takes precedence
cat > /etc/udev/rules.d/55-yubikey-ccid.rules << 'EOF'
# YubiKey CCID Support for pcscd
# Fixes LIBUSB_ERROR_BUSY crashes when pcscd starts
# Problem: libfido2's 60-fido-id.rules can block CCID interface access
# Solution: Higher-priority rule ensures pcscd can use CCID

SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", MODE="0666"
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{ID_SMARTCARD_READER}="1"
EOF

echo "✓ Created /etc/udev/rules.d/55-yubikey-ccid.rules"

# Reload and trigger udev
printf "Reloading udev rules...\n"
udevadm control --reload-rules
udevadm trigger
echo "✓ udev rules reloaded"

# Restart pcscd
printf "Restarting pcscd service...\n"
systemctl restart pcscd
sleep 1

if systemctl is-active --quiet pcscd; then
    printf "\n✅ YubiKey pcscd fix complete!\n"
    printf "   pcscd is now running. Test with:\n"
    printf "   • gpg --card-status\n"
    printf "   • yubico-authenticator\n"
else
    printf "\n❌ pcscd failed to start. Check logs:\n"
    systemctl status pcscd --no-pager | tail -10
    exit 1
fi
