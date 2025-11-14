#!/bin/sh
# Activates the podman socket across distros (systemd or OpenRC)
#
# This script is intended to be a post-install helper that:
# - enables and starts `podman.socket` on systemd systems (system or user)
# - enables linger and user socket for rootless users where possible
# - falls back to OpenRC (`rc-update`/`rc-service`) on Alpine-like systems
# - prints helpful instructions on unsupported init systems
#
# Usage:
#   podman-postinstall.sh [--user USER]
#
# If run as root, it will enable system-level socket if available. If
# `--user` is provided or SUDO_USER is set, it will also enable rootless
# systemd --user socket for that specific user (adding linger if needed).

set -eu

info() { printf "[INFO] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
err() { printf "[ERROR] %s\n" "$*"; }

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

# If we don't have a target user from args, prefer SUDO_USER and then whoami
if [ -z "$TARGET_USER" ]; then
	if [ -n "$SUDO_USER" ]; then
		TARGET_USER="$SUDO_USER"
	else
		# whoami may return root if run as root; that's ok.
		if command -v whoami >/dev/null 2>&1; then
			TARGET_USER=$(whoami)
		fi
	fi
fi

has_cmd() { command -v "$1" >/dev/null 2>&1; }

is_systemd_running() {
	# systemd is PID 1 in most systems with systemctl available
	if ! has_cmd systemctl; then
		return 1
	fi
	if [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ]; then
		return 0
	fi
	return 1
}

enable_system_socket() {
	if ! has_cmd systemctl; then
		warn "systemctl not found; skipping system-level systemd activation"
		return 0
	fi

	if systemctl list-unit-files --type=socket | grep -q 'podman.socket'; then
		info "Enabling and starting system-level podman.socket"
		systemctl enable --now podman.socket || warn "Failed to enable podman.socket"
	else
		# If socket not present, attempt to fallback to enabling the podman service
		if systemctl list-unit-files --type=service | grep -q 'podman.service'; then
			info "podman.socket not found; enabling podman.service instead"
			systemctl enable --now podman.service || warn "Failed to enable podman.service"
		else
			warn "podman.socket and podman.service unit not found for system instance; skipping"
		fi
	fi
}

enable_user_socket() {
	USERNAME="$1"
	if [ -z "$USERNAME" ]; then
		warn "No user supplied to enable_user_socket"
		return 1
	fi

	if ! has_cmd systemctl; then
		warn "systemctl not found; cannot enable user socket for $USERNAME"
		return 1
	fi

	# Ensure linger is enabled so user services can run without an active login session
	if has_cmd loginctl; then
		info "Enabling linger for $USERNAME"
		loginctl enable-linger "$USERNAME" || warn "loginctl enable-linger failed for $USERNAME"
	else
		warn "loginctl not available to manage linger for $USERNAME"
	fi

	# Run systemctl --user as the target user
	# Prefer runuser, then su, then sudo -u for compatibility
	enable_cmd="systemctl --user enable --now podman.socket || systemctl --user start podman.socket || true"

	check_unit_cmd="systemctl --user list-unit-files | grep -q 'podman.socket'"

	# Check whether user-level systemctl exists for the user; if not, we still try
	if has_cmd runuser; then
		info "Enabling user systemd socket for $USERNAME (runuser)"
		if runuser -l "$USERNAME" -c "$check_unit_cmd" >/dev/null 2>&1; then
			runuser -l "$USERNAME" -c "$enable_cmd" || warn "Failed enabling user socket via runuser"
		else
			warn "User unit podman.socket not found for $USERNAME; skipping user enable"
		fi
	elif has_cmd su; then
		info "Enabling user systemd socket for $USERNAME (su)"
		if su - "$USERNAME" -c "$check_unit_cmd" >/dev/null 2>&1; then
			su - "$USERNAME" -c "$enable_cmd" || warn "Failed enabling user socket via su"
		else
			warn "User unit podman.socket not found for $USERNAME; skipping user enable"
		fi
	elif has_cmd sudo; then
		info "Enabling user systemd socket for $USERNAME (sudo)"
		if sudo -u "$USERNAME" sh -c "$check_unit_cmd" >/dev/null 2>&1; then
			sudo -u "$USERNAME" sh -c "$enable_cmd" || warn "Failed enabling user socket via sudo"
		else
			warn "User unit podman.socket not found for $USERNAME; skipping user enable"
		fi
	else
		warn "No method to run systemctl --user as $USERNAME; tell them to run: $enable_cmd"
	fi
}

enable_openrc_socket() {
	# Alpine/OpenRC systems may provide a service script rather than a systemd unit
	if [ -f /etc/init.d/podman ]; then
		if has_cmd rc-update; then
			info "Adding podman to default runlevel and starting service (OpenRC)"
			rc-update add podman default || warn "Failed to add to runlevel"
		fi
		if has_cmd rc-service; then
			rc-service podman start || warn "Failed to start podman OpenRC service"
		fi
	else
		warn "OpenRC podman init script not found; skipping"
	fi
}

main() {
	if is_systemd_running; then
		info "Detected systemd"

		# Enable system-wide socket if present
		if [ "$(id -u)" -eq 0 ]; then
			enable_system_socket
		else
			info "Non-root; enabling user-level socket for $(whoami)"
			enable_user_socket "$(whoami)"
		fi

		# If we have a target (non-root) user and we're root, enable their user socket too
		if [ "$(id -u)" -eq 0 ] && [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
			enable_user_socket "$TARGET_USER"
		fi
	else
		info "systemd not running"
		# Try openrc path
		enable_openrc_socket

		# Fallback: output instructions
		info "If your system does not use systemd/OpenRC, enable podman socket manually or consult documentation"
	fi

	info "podman socket activation script finished"
}

main "$@"

