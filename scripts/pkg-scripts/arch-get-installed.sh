#!/usr/bin/env bash

# Simplified: Generates two installation commands for explicitly installed packages
# 1) Official (pacman)   2) AUR (paru/yay)
# Output: output/arch-packages.md with two lines:
# pacman -S <repo_pkgs>
# paru   -S <aur_pkgs>
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/output"
OUTPUT_FILE="${OUT_DIR}/arch-packages.md"

if ! command -v pacman >/dev/null 2>&1; then
  printf 'Error: pacman not found.\n' >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

# Explicitly installed packages (Repo + Foreign)
explicit_list="$(pacman -Qqe 2>/dev/null || true)"
# Foreign (AUR/manual) packages
aur_list="$(pacman -Qqm 2>/dev/null || true)"

repo_list=""
if [[ -n ${explicit_list} ]]; then
  if [[ -n ${aur_list} ]]; then
    repo_list="$(comm -23 <(printf '%s\n' "${explicit_list}" | sort -u) <(printf '%s\n' "${aur_list}" | sort -u))"
  else
    repo_list="$(printf '%s\n' "${explicit_list}" | sort -u)"
  fi
fi

aur_sorted=""
if [[ -n ${aur_list} ]]; then
  aur_sorted="$(printf '%s\n' "${aur_list}" | sort -u)"
fi

# Pack into a single command line
repo_cmd="pacman -S"
aur_cmd="paru -S"

if [[ -n ${repo_list} ]]; then
  # shellcheck disable=SC2086
  repo_cmd+=" $(printf '%s ' ${repo_list})"
fi
if [[ -n ${aur_sorted} ]]; then
  # shellcheck disable=SC2086
  aur_cmd+=" $(printf '%s ' ${aur_sorted})"
fi

{
  printf '# Arch Install Commands\n'
  printf 'Generated: %s\n\n' "$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  if [[ -n ${repo_list} ]]; then
    printf '%s\n' "${repo_cmd}" | sed 's/ $//' 
  else
    printf '# No explicit repo packages found\n'
  fi
  if [[ -n ${aur_sorted} ]]; then
    printf '%s\n' "${aur_cmd}" | sed 's/ $//' 
  else
    printf '# No AUR packages found\n'
  fi
} > "${OUTPUT_FILE}"

printf 'Created file: %s\n' "${OUTPUT_FILE}"