#!/usr/bin/env bash

# Post-installation script to set up the environment
# To be installed after the main installation process
# Only for OS/DE independent programs and configurations
# See other scripts for OS/DE specific setups
# Work in progress - use at your own risk

set -euo pipefail

#------------------------------------------------------------------------------
# DISPLAY CONFIGURATION
#------------------------------------------------------------------------------
# Colors and symbols for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK='✅'
INFO='ℹ️'
ERROR='❌'
DRY='🧪'

usage() {
    cat <<'EOF'
Usage: postinstall.sh [options]

Options:
  -n, --dry-run    Validate prerequisites and show planned actions without running them
  -h, --help       Show this help message
EOF
}

DRY_RUN=false
ORIGINAL_ARGS=("$@")

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

info_msg() { echo -e "${INFO} ${YELLOW}$1${NC}"; }
success_msg() { echo -e "${CHECK} ${GREEN}$1${NC}"; }
error_msg() { echo -e "${ERROR} ${RED}$1${NC}" >&2; }
dry_msg() { echo -e "${DRY} ${YELLOW}$1${NC}"; }

resolve_repo_root() {
    local candidate

    if [[ -n "${TL40_DOTS_ROOT:-}" ]]; then
        if candidate="$(cd "${TL40_DOTS_ROOT}" && pwd 2>/dev/null)"; then
            if [[ -d "${candidate}/scripts/pkg-scripts" ]]; then
                printf '%s\n' "${candidate}"
                return 0
            fi
        fi
    fi

    local source_path="${BASH_SOURCE[0]:-}"
    case "${source_path}" in
        /dev/fd/*|pipe:*|*://*)
            ;;
        *)
            if candidate="$(cd "$(dirname "${source_path}")" && pwd 2>/dev/null)"; then
                if candidate="$(cd "${candidate}/../.." && pwd 2>/dev/null)"; then
                    if [[ -d "${candidate}/scripts/pkg-scripts" ]]; then
                        printf '%s\n' "${candidate}"
                        return 0
                    fi
                fi
            fi
            ;;
    esac

    if command -v git >/dev/null 2>&1; then
        if candidate="$(git rev-parse --show-toplevel 2>/dev/null)"; then
            if [[ -d "${candidate}/scripts/pkg-scripts" ]]; then
                printf '%s\n' "${candidate}"
                return 0
            fi
        fi
    fi

    return 1
}

ensure_repo_and_reexec() {
    local repo_url="${TL40_DOTS_REPO:-https://github.com/TuxLux40/TL40-Dots.git}"
    local branch="${TL40_DOTS_BRANCH:-main}"
    local target_dir_default="${TL40_DOTS_DIR:-$HOME/Projects/TL40-Dots}"
    local target_dir
    case "${target_dir_default}" in
        ~)
            target_dir="${HOME}"
            ;;
        ~/*)
            target_dir="${HOME}/${target_dir_default#~/}"
            ;;
        /*)
            target_dir="${target_dir_default}"
            ;;
        *)
            target_dir="${PWD}/${target_dir_default}"
            ;;
    esac

    if ! command -v git >/dev/null 2>&1; then
        error_msg "Git is required to bootstrap the repository."
        exit 1
    fi

    info_msg "Preparing TL40-Dots repository at ${target_dir}."

    if [[ -d "${target_dir}/.git" ]]; then
        info_msg "Updating existing repository checkout."
        git -C "${target_dir}" fetch --depth=1 origin "${branch}"
        git -C "${target_dir}" checkout "${branch}"
        git -C "${target_dir}" pull --ff-only origin "${branch}"
    else
        if [[ -e "${target_dir}" && ! -d "${target_dir}" ]]; then
            error_msg "Target path exists and is not a directory: ${target_dir}."
            exit 1
        fi
        mkdir -p "${target_dir}"
        if [[ -n "$(ls -A "${target_dir}" 2>/dev/null)" ]]; then
            error_msg "Target directory exists and is not empty: ${target_dir}."
            exit 1
        fi
        info_msg "Cloning repository from ${repo_url}."
        git clone --depth=1 --branch "${branch}" "${repo_url}" "${target_dir}"
    fi

    info_msg "Restarting postinstall from local checkout."
    exec bash "${target_dir}/scripts/postinstall/postinstall.sh" "${ORIGINAL_ARGS[@]}"
}

if ! ROOT_DIR="$(resolve_repo_root)"; then
    ensure_repo_and_reexec
fi

cd "${ROOT_DIR}" >/dev/null 2>&1 || {
    error_msg "Failed to change directory to repository root: ${ROOT_DIR}."
    exit 1
}

detect_distro() {
    if [[ -n "${OS_FAMILY:-}" && -n "${PKG_MANAGER:-}" ]]; then
        return
    fi

    if [[ ! -r /etc/os-release ]]; then
        error_msg "Cannot detect distribution: /etc/os-release missing."
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
        error_msg "Unsupported distribution: ${ID}"
        exit 1
    fi

    case "${pkg_manager}" in
        pacman)
            export PKG_INSTALL_CMD='sudo pacman -S --noconfirm --needed'
            export PKG_UPDATE_CMD='sudo pacman -Sy'
            ;;
        apt)
            export PKG_INSTALL_CMD='sudo apt-get install -y'
            export PKG_UPDATE_CMD='sudo apt-get update'
            ;;
        dnf)
            export PKG_INSTALL_CMD='sudo dnf install -y'
            export PKG_UPDATE_CMD='sudo dnf update -y'
            ;;
        zypper)
            export PKG_INSTALL_CMD='sudo zypper --non-interactive install'
            export PKG_UPDATE_CMD='sudo zypper --non-interactive refresh'
            ;;
        apk)
            export PKG_INSTALL_CMD='sudo apk add --no-progress'
            export PKG_UPDATE_CMD='sudo apk update'
            ;;
    esac

    export OS_ID="${ID}"
    export OS_ID_LIKE="${ID_LIKE:-}"
    export OS_NAME="${PRETTY_NAME:-$NAME}"
    export OS_FAMILY="${os_family}"
    export PKG_MANAGER="${pkg_manager}"
}

check_dependencies() {
    local -a required_cmds=(sudo curl git chsh bash sh)
    case "${PKG_MANAGER}" in
        pacman)
            required_cmds+=(pacman makepkg)
            ;;
        apt)
            required_cmds+=(apt-get)
            ;;
        dnf)
            required_cmds+=(dnf)
            ;;
        zypper)
            required_cmds+=(zypper)
            ;;
        apk)
            required_cmds+=(apk)
            ;;
    esac

    local -a missing_cmds=()
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_cmds+=("$cmd")
        fi
    done

    local -a required_scripts=(
        "${ROOT_DIR}/scripts/pkg-scripts/misc-tools.sh"
        "${ROOT_DIR}/scripts/pkg-scripts/fish-install.sh"
        "${ROOT_DIR}/scripts/pkg-scripts/atuin-install.sh"
        "${ROOT_DIR}/scripts/pkg-scripts/tailscale-install.sh"
        "${ROOT_DIR}/scripts/pkg-scripts/starship-install.sh"
        "${ROOT_DIR}/scripts/pkg-scripts/chezmoi-install.sh"
        "${ROOT_DIR}/scripts/pkg-scripts/homebrew-install.sh"
        "${ROOT_DIR}/scripts/postinstall/dotfile-symlinks.sh"
    )

    if [[ "${OS_FAMILY}" == "arch" ]]; then
        required_scripts+=("${ROOT_DIR}/scripts/pkg-scripts/paru-install.sh")
    fi

    local -a missing_scripts=()
    for script_path in "${required_scripts[@]}"; do
        if [[ ! -f "$script_path" ]]; then
            missing_scripts+=("$script_path")
        fi
    done

    if (( ${#missing_cmds[@]} > 0 || ${#missing_scripts[@]} > 0 )); then
        if (( ${#missing_cmds[@]} > 0 )); then
            error_msg "Missing required commands: ${missing_cmds[*]}"
        fi
        if (( ${#missing_scripts[@]} > 0 )); then
            error_msg "Missing required scripts: ${missing_scripts[*]}"
        fi
        return 1
    fi

    return 0
}

run_step() {
    local description="$1"
    shift
    if $DRY_RUN; then
        dry_msg "Would ${description}."
        return 0
    fi

    info_msg "${description}"
    "$@"
    success_msg "${description} completed."
}

run_script() {
    local description="$1"
    local interpreter="$2"
    local script_path="$3"
    shift 3
    run_step "${description}" "$interpreter" "$script_path" "$@"
}

install_paru_if_needed() {
    if [[ "${OS_FAMILY}" != "arch" ]]; then
        info_msg "Skipping paru installation on ${OS_NAME}."
        return
    fi

    if command -v paru >/dev/null 2>&1; then
        success_msg "Paru is already installed."
        return
    fi

    info_msg "Paru not found. Preparing installation."
    run_script "Install paru AUR helper" bash "${ROOT_DIR}/scripts/pkg-scripts/paru-install.sh"
}

detect_distro

info_msg "Post-installation script started on ${OS_NAME} (package manager: ${PKG_MANAGER})."

if check_dependencies; then
    if $DRY_RUN; then
        dry_msg "All required commands and scripts are present."
    else
        success_msg "All required commands and scripts are present."
    fi
else
    error_msg "Dependency check failed."
    exit 1
fi

install_paru_if_needed

run_script "Install common CLI tools" bash "${ROOT_DIR}/scripts/pkg-scripts/misc-tools.sh"
run_script "Install and configure Fish shell" bash "${ROOT_DIR}/scripts/pkg-scripts/fish-install.sh"
run_script "Install Starship prompt" sh "${ROOT_DIR}/scripts/pkg-scripts/starship-install.sh"
run_script "Install Atuin shell history" sh "${ROOT_DIR}/scripts/pkg-scripts/atuin-install.sh"
run_script "Install Tailscale" sh "${ROOT_DIR}/scripts/pkg-scripts/tailscale-install.sh"
run_script "Install ChezMoi" sh "${ROOT_DIR}/scripts/pkg-scripts/chezmoi-install.sh"
run_script "Install Homebrew" bash "${ROOT_DIR}/scripts/pkg-scripts/homebrew-install.sh"

if $DRY_RUN; then
    dry_msg "Would create dotfile symlinks."
else
    run_script "Create dotfile symlinks" bash "${ROOT_DIR}/scripts/postinstall/dotfile-symlinks.sh"
fi

if $DRY_RUN; then
    dry_msg "Dry-run completed. No changes were made."
else
    success_msg "Post-installation script completed."
fi
