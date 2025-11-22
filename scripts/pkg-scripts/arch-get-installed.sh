#!/usr/bin/env bash

# Vereinfacht: Erzeugt zwei Installationsbefehle für explizit installierte Pakete
# 1) Offizielle (pacman)   2) AUR (paru/yay)
# Ausgabe: output/arch-packages.md mit zwei Zeilen:
# pacman -S <repo_pkgs>
# paru   -S <aur_pkgs>
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/output"
OUTPUT_FILE="${OUT_DIR}/arch-packages.md"

if ! command -v pacman >/dev/null 2>&1; then
  printf 'Fehler: pacman nicht gefunden.\n' >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

# Explizit installierte Pakete (Repo + Foreign)
explicit_list="$(pacman -Qqe 2>/dev/null || true)"
# Foreign (AUR/Manuell) Pakete
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

# In eine einzige Befehlszeile packen
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
  printf 'Generiert: %s\n\n' "$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  if [[ -n ${repo_list} ]]; then
    printf '%s\n' "${repo_cmd}" | sed 's/ $//' 
  else
    printf '# Keine expliziten Repo-Pakete gefunden\n'
  fi
  if [[ -n ${aur_sorted} ]]; then
    printf '%s\n' "${aur_cmd}" | sed 's/ $//' 
  else
    printf '# Keine AUR-Pakete gefunden\n'
  fi
} > "${OUTPUT_FILE}"

printf 'Erstellt Datei: %s\n' "${OUTPUT_FILE}"