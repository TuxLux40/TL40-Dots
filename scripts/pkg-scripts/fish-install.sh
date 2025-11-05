#!/usr/bin/env bash

# Fish shell installation script, sets up Fish as default shell, independent of distro
# To be consumed by the post-installation script

set -euo pipefail

log_info() {
	printf '[fish-install] %s\n' "$1"
}

detect_env() {
	local env_family="${OS_FAMILY:-}"
	local env_pkg="${PKG_MANAGER:-}"

	if [[ -n "${env_family}" && -n "${env_pkg}" ]]; then
		local env_family_lc="${env_family,,}"
		local env_pkg_lc="${env_pkg,,}"
		if [[ "${env_family_lc}" != "unknown" && "${env_pkg_lc}" != "unknown" ]]; then
			export OS_FAMILY="${env_family}"
			export PKG_MANAGER="${env_pkg}"
			return
		fi
	fi

	if [[ ! -r /etc/os-release ]]; then
		echo "Unable to detect operating system." >&2
		exit 1
	fi

	# shellcheck disable=SC1091
	. /etc/os-release

	local id_lc="${ID,,}"
	local id_like_lc=""
	if [[ -n "${ID_LIKE:-}" ]]; then
		id_like_lc="${ID_LIKE,,}"
	fi

	local os_family=""
	local pkg_manager=""

	case "${id_lc}" in
		arch|artix|manjaro|endeavouros)
			os_family="arch"
			pkg_manager="pacman"
			;;
		debian|ubuntu|pop|linuxmint|elementary|zorin|kali|raspbian)
			os_family="debian"
			pkg_manager="apt"
			;;
		fedora|rhel|centos|rocky|almalinux|ol|oracle|amazon|alma|rockylinux)
			os_family="fedora"
			pkg_manager="dnf"
			;;
		opensuse*|sles)
			os_family="suse"
			pkg_manager="zypper"
			;;
		alpine)
			os_family="alpine"
			pkg_manager="apk"
			;;
		*)
			if [[ "${id_like_lc}" == *arch* ]]; then
				os_family="arch"
				pkg_manager="pacman"
			elif [[ "${id_like_lc}" == *debian* ]]; then
				os_family="debian"
				pkg_manager="apt"
			elif [[ "${id_like_lc}" == *rhel* || "${id_like_lc}" == *fedora* ]]; then
				os_family="fedora"
				pkg_manager="dnf"
			elif [[ "${id_like_lc}" == *suse* ]]; then
				os_family="suse"
				pkg_manager="zypper"
			fi
			;;
	esac

	if [[ -z "${pkg_manager}" ]]; then
		if command -v brew >/dev/null 2>&1; then
			os_family="darwin"
			pkg_manager="brew"
		else
			echo "Unsupported distribution: ${ID}" >&2
			exit 1
		fi
	fi

	export OS_FAMILY="${os_family}"
	export PKG_MANAGER="${pkg_manager}"
}

install_fish() {
	case "${PKG_MANAGER}" in
		pacman)
			sudo pacman -Sy --noconfirm --needed fish
			;;
		apt)
			sudo apt-get update
			sudo apt-get install -y fish
			;;
		dnf)
			sudo dnf install -y fish
			;;
		zypper)
			sudo zypper --non-interactive install fish
			;;
		apk)
			sudo apk update
			sudo apk add --no-progress fish
			;;
		brew)
			brew install fish
			;;
		*)
			echo "Unsupported package manager: ${PKG_MANAGER}" >&2
			exit 1
			;;
	esac
}

ensure_shell_registered() {
	local fish_path
	fish_path="$(command -v fish || true)"
	if [[ -z "${fish_path}" ]]; then
		echo "Fish binary not found after installation." >&2
		exit 1
	fi

	if ! grep -Fxq "${fish_path}" /etc/shells; then
		printf '%s\n' "${fish_path}" | sudo tee -a /etc/shells >/dev/null
	fi
}

set_default_shell() {
	local fish_path target_user current_shell
	fish_path="$(command -v fish)"
	target_user="${SUDO_USER:-$USER}"
	if command -v getent >/dev/null 2>&1; then
		current_shell="$(getent passwd "${target_user}" | cut -d: -f7)"
	elif [[ "${OSTYPE:-}" == darwin* ]]; then
		current_shell="$(dscl . -read "/Users/${target_user}" UserShell 2>/dev/null | awk '{print $2}')"
	else
		current_shell="${SHELL:-}"
	fi

	if [[ "${current_shell}" == "${fish_path}" ]]; then
		log_info "Fish is already the default shell for ${target_user}."
		return
	fi

	if chsh -s "${fish_path}" "${target_user}"; then
		log_info "Default shell set to fish for ${target_user}."
	else
		echo "Failed to set fish as the default shell for ${target_user}." >&2
		exit 1
	fi
}

log_info "Preparing to install fish shell."

detect_env

log_info "Detected environment: family=${OS_FAMILY}, pkg_manager=${PKG_MANAGER}."

if command -v fish >/dev/null 2>&1; then
	log_info "Fish is already installed. Ensuring it is registered and set as default."
else
	install_fish
fi

ensure_shell_registered
set_default_shell

log_info "Fish installation and default shell configuration completed."
