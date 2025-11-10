#!/usr/bin/env bash

# Standalone script to install fastfetch
set -euo pipefail

install_fastfetch() {
    if ! command -v fastfetch >/dev/null 2>&1; then
        local arch
        arch="$(uname -m)"
        local fastfetch_url
        if [[ "$arch" == "x86_64" ]]; then
            fastfetch_url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz"
        elif [[ "$arch" == "aarch64" ]]; then
            fastfetch_url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64.tar.gz"
        else
            echo "Unsupported architecture: $arch" >&2
            return 1
        fi
        local tmp_dir
        tmp_dir="$(mktemp -d)"
        trap 'rm -rf "${tmp_dir}"' EXIT
        echo "Downloading fastfetch for $arch..."
        curl -L "${fastfetch_url}" -o "${tmp_dir}/fastfetch.tar.gz"
        tar -xzf "${tmp_dir}/fastfetch.tar.gz" -C "${tmp_dir}"
        sudo cp "${tmp_dir}/fastfetch-linux-${arch}/usr/bin/fastfetch" /usr/local/bin/
        rm -rf "${tmp_dir}"
        trap - EXIT
        echo "Fastfetch installed successfully."
    else
        echo "Fastfetch is already installed."
    fi
}

install_fastfetch