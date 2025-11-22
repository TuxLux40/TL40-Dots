#!/bin/sh
# Activates the podman socket across distros (systemd or OpenRC)
#
# This script enables and starts podman.socket on systemd systems (system or user),
# enables linger and user socket for rootless users, or falls back to OpenRC.
#
# Usage: podman-postinstall.sh [--user USER]

set -eu

info() { printf "[INFO] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }

SUDO_USER=${SUDO_USER:-}
TARGET_USER=""

usage() {
	cat <<EOF
Usage: $0 [--user USER]

Enable podman socket activation where possible (systemd or OpenRC).
EOF
	exit 0
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		-u|--user)
			TARGET_USER="$2"; shift 2 || true;;
		-h|--help)
			usage;;
		*)
			printf "Unknown arg: %s\n" "$1"; usage;;
	esac
done

if [ -z "$TARGET_USER" ]; then
	if [ -n "$SUDO_USER" ]; then
		TARGET_USER="$SUDO_USER"
	else
		TARGET_USER=$(whoami 2>/dev/null || echo "")
	fi
fi

has_cmd() { command -v "$1" >/dev/null 2>&1; }

is_systemd_running() {
	has_cmd systemctl && [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ]
}

run_as_user() {
	local user="$1" cmd="$2"
	if has_cmd runuser; then
		runuser -l "$user" -c "$cmd"
	elif has_cmd su; then
		su - "$user" -c "$cmd"
	elif has_cmd sudo; then
		sudo -u "$user" sh -c "$cmd"
	else
		return 1
	fi
}

enable_system_socket() {
	if ! has_cmd systemctl; then
		warn "systemctl not found; skipping system-level activation"
		return
	fi
	if systemctl list-unit-files --type=socket | grep -q 'podman.socket'; then
		info "Enabling system podman.socket"
		systemctl enable --now podman.socket || warn "Failed to enable podman.socket"
	elif systemctl list-unit-files --type=service | grep -q 'podman.service'; then
		info "podman.socket not found; enabling podman.service"
		systemctl enable --now podman.service || warn "Failed to enable podman.service"
	else
		warn "No podman unit found; skipping"
	fi
}

enable_user_socket() {
	local user="$1"
	if [ -z "$user" ]; then
		warn "No user supplied"
		return 1
	fi
	if ! has_cmd systemctl; then
		warn "systemctl not found; cannot enable user socket"
		return 1
	fi
	if has_cmd loginctl; then
		info "Enabling linger for $user"
		loginctl enable-linger "$user" || warn "loginctl enable-linger failed"
	else
		warn "loginctl not available"
	fi
	local enable_cmd="systemctl --user enable --now podman.socket || systemctl --user start podman.socket || true"
	local check_cmd="systemctl --user list-unit-files | grep -q 'podman.socket'"
	info "Enabling user socket for $user"
	if run_as_user "$user" "$check_cmd" >/dev/null 2>&1; then
		run_as_user "$user" "$enable_cmd" || warn "Failed to enable user socket"
	else
		warn "User podman.socket not found; skipping"
	fi
}

enable_openrc_socket() {
	if [ -f /etc/init.d/podman ]; then
		if has_cmd rc-update; then
			info "Adding podman to default runlevel"
			rc-update add podman default || warn "Failed to add to runlevel"
		fi
		if has_cmd rc-service; then
			rc-service podman start || warn "Failed to start service"
		fi
	else
		warn "OpenRC podman init script not found; skipping"
	fi
}

main() {
	if is_systemd_running; then
		info "Detected systemd"
		if [ "$(id -u)" -eq 0 ]; then
			enable_system_socket
			[ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ] && enable_user_socket "$TARGET_USER"
		else
			enable_user_socket "$(whoami)"
		fi
	else
		info "systemd not running"
		enable_openrc_socket
		info "For non-systemd/OpenRC systems, enable podman socket manually"
	fi
	info "Script finished"
}

main "$@"

