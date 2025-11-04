#!/usr/bin/env bash
# Ensure lactd and tailscaled run now and on boot without prompting for a password.

set -euo pipefail

# Require systemd
if ! command -v systemctl >/dev/null 2>&1; then
    echo "Error: systemctl not found; systemd is required." >&2
    exit 1
fi
if [ "${CI:-}" != "true" ] && [ "$(cat /proc/1/comm 2>/dev/null || echo unknown)" != "systemd" ]; then
    echo "Error: PID 1 is not systemd; cannot configure autostart." >&2
    exit 1
fi

# Use passwordless sudo if not root
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if sudo -n true 2>/dev/null; then
        SUDO="sudo -n"
    else
        echo "Error: passwordless sudo required. Re-run as root or configure NOPASSWD." >&2
        exit 1
    fi
fi

# Run the requested commands
$SUDO systemctl enable --now lactd
$SUDO systemctl start tailscaled

# Also ensure tailscaled starts on boot
$SUDO systemctl enable tailscaled

# Quick verification
$SUDO systemctl is-enabled lactd >/dev/null
$SUDO systemctl is-enabled tailscaled >/dev/null

echo "Configured: lactd enabled and running; tailscaled started and enabled for boot."