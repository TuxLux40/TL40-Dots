#!/usr/bin/env bash

# Standalone script to install fastfetch
set -euo pipefail

install_fastfetch() {
    if ! command -v fastfetch >/dev/null 2>&1; then
        local fastfetch_url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz"
        local tmp_dir
        tmp_dir="$(mktemp -d)"
        trap 'rm -rf "${tmp_dir}"' EXIT
        curl -L "${fastfetch_url}" -o "${tmp_dir}/fastfetch.tar.gz"
        tar -xzf "${tmp_dir}/fastfetch.tar.gz" -C "${tmp_dir}"
        sudo cp "${tmp_dir}/fastfetch-linux-amd64/usr/bin/fastfetch" /usr/local/bin/
        rm -rf "${tmp_dir}"
        trap - EXIT
    fi
}

install_fastfetch