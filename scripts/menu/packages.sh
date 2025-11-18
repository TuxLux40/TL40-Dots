#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/actions.sh
source "${SCRIPT_DIR}/../lib/actions.sh"

show_help() {
        cat <<'EOF'
Package and runtime installer menu

Options:
    -n, --dry-run   Preview installer commands
    -h, --help      Show this help
EOF
}

tl40_parse_common_args "$@"
if (( TL40_SHOW_HELP )); then
    show_help
    exit 0
fi

install_flatpak_cli() {
    local cmd=()
    case "${PKG_MANAGER:-}" in
        pacman) cmd=(sudo pacman -S --needed flatpak) ;;
        apt) cmd=(sudo apt install -y flatpak) ;;
        dnf) cmd=(sudo dnf install -y flatpak) ;;
        zypper) cmd=(sudo zypper install -y flatpak) ;;
        apk) cmd=(sudo apk add flatpak) ;;
        brew) cmd=(brew install flatpak) ;;
        *) tl40_msg_box "Flatpak" "Install Flatpak manually for ${PKG_MANAGER:-unknown}." ; return ;;
    esac
    tl40_run_in_shell "Install Flatpak" "${cmd[@]}"
}

install_rustup_cargo() {
    tl40_run_in_shell "Install rustup/cargo" bash -c "set -euo pipefail
if command -v cargo >/dev/null 2>&1; then
    echo 'cargo already installed'
    exit 0
fi
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source '$HOME/.cargo/env'
cargo --version"
}

install_homebrew() {
    tl40_run_in_shell "Install Homebrew" "${TL40_SCRIPTS_DIR}/pkg-scripts/homebrew-install.sh"
}

install_paru() {
    if [[ "${PKG_MANAGER:-}" != "pacman" ]]; then
        tl40_msg_box "paru" "paru only applies on Arch-based systems."
        return
    fi
    tl40_run_in_shell "Install paru" "${TL40_SCRIPTS_DIR}/pkg-scripts/paru-install.sh"
}

install_pip() {
    local cmd=()
    case "${PKG_MANAGER:-}" in
        pacman) cmd=(sudo pacman -S --needed python-pip) ;;
        apt) cmd=(sudo apt install -y python3-pip) ;;
        dnf) cmd=(sudo dnf install -y python3-pip) ;;
        zypper) cmd=(sudo zypper install -y python3-pip) ;;
        apk) cmd=(sudo apk add py3-pip) ;;
        brew) cmd=(brew install python@3) ;;
        *) tl40_msg_box "pip" "Install pip manually for ${PKG_MANAGER:-unknown}." ; return ;;
    esac
    tl40_run_in_shell "Install pip" "${cmd[@]}"
}

install_npm() {
    local cmd=()
    case "${PKG_MANAGER:-}" in
        pacman) cmd=(sudo pacman -S --needed nodejs npm) ;;
        apt) cmd=(sudo apt install -y nodejs npm) ;;
        dnf) cmd=(sudo dnf install -y nodejs npm) ;;
        zypper) cmd=(sudo zypper install -y nodejs npm) ;;
        apk) cmd=(sudo apk add nodejs npm) ;;
        brew) cmd=(brew install node) ;;
        *) tl40_msg_box "npm" "Install Node.js/npm manually for ${PKG_MANAGER:-unknown}." ; return ;;
    esac
    tl40_run_in_shell "Install Node.js + npm" "${cmd[@]}"
}

install_podman() {
    local cmd=()
    case "${PKG_MANAGER:-}" in
        pacman) cmd=(sudo pacman -S --needed podman podman-compose) ;;
        apt) cmd=(sudo apt install -y podman) ;;
        dnf) cmd=(sudo dnf install -y podman podman-compose) ;;
        zypper) cmd=(sudo zypper install -y podman podman-compose) ;;
        apk) cmd=(sudo apk add podman) ;;
        brew) cmd=(brew install podman) ;;
        *) tl40_msg_box "Podman" "Install Podman manually for ${PKG_MANAGER:-unknown}." ; return ;;
    esac
    tl40_run_in_shell "Install Podman" "${cmd[@]}"
}

while true; do
    choice=$(tl40_menu_select "Package & runtime installers" "Install base package managers and supporting runtimes" \
        flatpak "Install Flatpak CLI plus recommended extras" \
        cargo "Install rustup/cargo toolchain manager" \
        brew "Install Homebrew (Linuxbrew) under /home/linuxbrew" \
        paru "Install paru AUR helper (Arch only)" \
        pip "Install Python pip from distro repos" \
        npm "Install Node.js and npm from distro repos" \
        podman "Install Podman along with the compose plugin" \
        back "Back") || exit 0
    case "$choice" in
        flatpak) install_flatpak_cli ;;
        cargo) install_rustup_cargo ;;
        brew) install_homebrew ;;
        paru) install_paru ;;
        pip) install_pip ;;
        npm) install_npm ;;
        podman) install_podman ;;
        back) exit 0 ;;
    esac
done
