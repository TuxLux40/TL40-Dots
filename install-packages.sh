#!/usr/bin/env bash
# blendos-systemyaml-linutil.sh
# Arch/CachyOS TUI to install packages from a BlendOS-style system.yaml.
# Deps: bash, awk, sed, grep, pacman, (paru|yay), flatpak; optional: gum, git, $EDITOR
set -euo pipefail

# ── Paths / Config ──────────────────────────────────────────────────────────────
APP_ID="blendos-systemyaml-linutil"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/${APP_ID}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/${APP_ID}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/${APP_ID}"
LOG="${STATE_DIR}/last-run.log"
CFG="${CFG_DIR}/config.env"
mkdir -p "$CFG_DIR" "$STATE_DIR" "$CACHE_DIR"

# ── TUI helpers (gum optional) ─────────────────────────────────────────────────
USE_GUM=${GUM:-1}
if (( USE_GUM==1 )) && command -v gum >/dev/null 2>&1; then
  TUI=1
  say(){ gum style --foreground "$2" "$1"; }
  ok(){ say "✓ $*" "#3adb76"; }
  warn(){ say "‼ $*" "#ffcc00"; }
  err(){ say "✗ $*" "#ff5c57"; }
  box(){ gum style --border normal --border-foreground "#39bae6" --padding "0 1" --margin "1 0" "$*"; }
  ask(){ gum input --placeholder "$1"; }
  choose(){ printf "%s\n" "$@" | gum choose; }
  multichoose(){ printf "%s\n" "$@" | gum choose --no-limit; }
  spin(){ gum spin --spinner dot --title "$1" -- "${@:2}"; }
else
  TUI=0
  ok(){ echo "OK $*"; } warn(){ echo "!! $*"; } err(){ echo "XX $*"; }
  box(){ echo "== $* =="; }
  ask(){ read -rp "$1: " REPLY; echo "$REPLY"; }
  choose(){ select a in "$@"; do echo "$a"; break; done; }
  multichoose(){ printf "%s\n" "$@"; }
  spin(){ "${@:2}"; }
fi

# ── Config load/save ───────────────────────────────────────────────────────────
YAML_SOURCE_TYPE="${YAML_SOURCE_TYPE:-}"
YAML_SOURCE="${YAML_SOURCE:-}"
YAML_IN_REPO_PATH="${YAML_IN_REPO_PATH:-}"
REPO_DIR="${REPO_DIR:-${CACHE_DIR}/repo}"

load_cfg(){ [[ -f "$CFG" ]] && # shellcheck disable=SC1090
  . "$CFG"; }
save_cfg(){
  cat >"$CFG" <<EOF
YAML_SOURCE_TYPE="$YAML_SOURCE_TYPE"
YAML_SOURCE="$YAML_SOURCE"
YAML_IN_REPO_PATH="$YAML_IN_REPO_PATH"
REPO_DIR="$REPO_DIR"
EOF
  ok "Saved config: $CFG"
}

# ── First-run wizard ───────────────────────────────────────────────────────────
first_run(){
  box "First setup • Pick YAML source"
  t=$(choose "GitHub repo (.git)" "Raw URL to YAML" "Local file path")
  case "$t" in
    "GitHub repo (.git)")
      YAML_SOURCE_TYPE="git"
      YAML_SOURCE="$(ask 'Repo URL (…/.git)')"
      [[ -z "$YAML_SOURCE" ]] && { err "Empty URL"; exit 1; }
      YAML_IN_REPO_PATH="$(ask 'Path to YAML inside repo (e.g. system.yaml)')"
      ;;
    "Raw URL to YAML")
      YAML_SOURCE_TYPE="url"
      YAML_SOURCE="$(ask 'Direct raw URL to YAML')"
      ;;
    "Local file path")
      YAML_SOURCE_TYPE="local"
      YAML_SOURCE="$(ask 'Absolute path to YAML file')"
      ;;
  esac
  save_cfg
}

# ── Fetch / Resolve YAML path ─────────────────────────────────────────────────
yaml_path=""
git_update(){
  if [[ ! -d "$REPO_DIR/.git" ]]; then
    mkdir -p "$REPO_DIR"
    spin "Cloning repo" git clone --depth=1 "$YAML_SOURCE" "$REPO_DIR"
  else
    spin "Updating repo" bash -c "cd '$REPO_DIR' && git fetch -q --all && git reset -q --hard origin/HEAD || git pull -q"
  fi
}
resolve_yaml(){
  case "$YAML_SOURCE_TYPE" in
    git)
      command -v git >/dev/null 2>&1 || { err "git not installed"; exit 1; }
      git_update
      yaml_path="${REPO_DIR}/${YAML_IN_REPO_PATH}"
      ;;
    url)
      tmp="${CACHE_DIR}/system.yaml"
      # Prefer curl if present, else wget
      if command -v curl >/dev/null 2>&1; then
        spin "Downloading YAML" curl -fsSL "$YAML_SOURCE" -o "$tmp"
      else
        spin "Downloading YAML" wget -qO "$tmp" "$YAML_SOURCE"
      fi
      yaml_path="$tmp"
      ;;
    local)
      yaml_path="$YAML_SOURCE"
      ;;
    *) err "Unknown YAML_SOURCE_TYPE"; exit 1;;
  esac
  [[ -f "$yaml_path" ]] || { err "YAML not found: $yaml_path"; exit 1; }
}

# ── YAML parsing (top-level simple lists) ──────────────────────────────────────
extract(){ # $1=key
  awk -v key="$1" '
    function trim(s){sub(/^[ \t\r\n]+/,"",s);sub(/[ \t\r\n]+$/,"",s);return s}
    $0 ~ "^[ \t]*"key"[ \t]*:[ \t]*($|#)" {in=1; next}
    in && $0 ~ "^[^ \t-]" {in=0}
    in && $0 ~ "^[ \t]*-[ \t]+" {
      s=$0; sub(/^[ \t]*-[ \t]+/,"",s); sub(/[ \t]*#.*/,"",s)
      gsub(/^"|"$/,"",s); gsub(/^'\''|'\''$/,"",s); s=trim(s); if(s!="") print s
    }' "$yaml_path" | sort -u
}

# ── AUR helper and PGP repair ─────────────────────────────────────────────────
AURH=""
command -v paru >/dev/null 2>&1 && AURH="paru"
[[ -z "$AURH" ]] && command -v yay >/dev/null 2>&1 && AURH="yay"

pgp_patterns='(PGP signature|invalid or corrupted package|key .* unknown|keyring|signature is marginal trust)'
installed_keyrings(){ ls /usr/share/pacman/keyrings/*.kbx 2>/dev/null | sed 's#.*/##; s/\.kbx$//' | tr '\n' ' '; }
pgp_repair(){
  warn "PGP/keyring issue detected. Repairing…"
  sudo pacman -Sy --noconfirm archlinux-keyring || true
  for pkg in chaotic-keyring cachyos-keyring; do
    sudo pacman -Si "$pkg" >/dev/null 2>&1 && sudo pacman -S --noconfirm "$pkg" || true
  done
  sudo pacman-key --init || true
  mapfile -t rings < <(installed_keyrings)
  [[ ${#rings[@]} -gt 0 ]] && sudo pacman-key --populate "${rings[@]}" || true
  sudo pacman-key --refresh-keys || true
}
run_with_pgp_retry(){ # title then command…
  local title="$1"; shift
  if spin "$title" "$@"; then return 0; fi
  # retry with capture
  if ( "$@" 2>&1 | tee /tmp/sysyaml.err.last >/dev/null ; exit ${PIPESTATUS[0]} ); then return 0; fi
  if grep -Eq "$pgp_patterns" /tmp/sysyaml.err.last 2>/dev/null; then
    pgp_repair
    spin "$title (retry after PGP repair)" "$@"
    return $?
  fi
  return 1
}

# ── Installers ────────────────────────────────────────────────────────────────
install_all(){
  local DRY="$1"
  : >"$LOG"
  mapfile -t REPO < <(extract packages || true)
  mapfile -t AUR  < <(extract aur-packages || true)
  mapfile -t FPS  < <(extract flatpaks || true)
  ok "Repo: ${#REPO[@]}  AUR: ${#AUR[@]}  Flatpaks: ${#FPS[@]}  Helper: ${AURH:-<none>}"

  # optional multi-select
  if (( TUI==1 )); then
    sel_repo=( $(printf "%s\n" "${REPO[@]}" | { [[ ${#REPO[@]} -gt 0 ]] && multichoose || true; } ) )
    sel_aur=(  $(printf "%s\n" "${AUR[@]}"  | { [[ ${#AUR[@]}  -gt 0 ]] && multichoose || true; } ) )
    sel_fp=(   $(printf "%s\n" "${FPS[@]}"  | { [[ ${#FPS[@]}  -gt 0 ]] && multichoose || true; } ) )
    ((${#sel_repo[@]})) || sel_repo=("${REPO[@]}")
    ((${#sel_aur[@]}))  || sel_aur=("${AUR[@]}")
    ((${#sel_fp[@]}))   || sel_fp=("${FPS[@]}")
  else
    sel_repo=("${REPO[@]}"); sel_aur=("${AUR[@]}"); sel_fp=("${FPS[@]}")
  fi

  # Repo batch, then per-package with AUR fallback
  success_repo=0 fail_repo=0
  if ((${#sel_repo[@]})); then
    if [[ "$DRY" == "1" ]]; then ok "[dry] repo: ${sel_repo[*]}"; else
      run_with_pgp_retry "Installing repo packages" sudo pacman -S --needed --noconfirm --noprogressbar "${sel_repo[@]}" || true
      # check missing
      missing=(); for p in "${sel_repo[@]}"; do pacman -Qi "$p" >/dev/null 2>&1 || missing+=("$p"); done
      if ((${#missing[@]})); then
        warn "Retrying ${#missing[@]} repo packages individually."
        for p in "${missing[@]}"; do
          if run_with_pgp_retry "repo $p" sudo pacman -S --needed --noconfirm --noprogressbar "$p"; then
            ((success_repo++))
          else
            if [[ -n "$AURH" ]]; then
              warn "Falling back to AUR for $p"
              if run_with_pgp_retry "aur $p" "$AURH" -S --needed --noconfirm --noprogressbar "$p"; then
                ((success_repo++))
              else
                ((fail_repo++)); err "[repo/aur] $p"
              fi
            else
              ((fail_repo++)); err "[repo] $p"
            fi
          fi
        done
      else
        success_repo=${#sel_repo[@]}
      fi
    fi
  fi

  # AUR
  success_aur=0 fail_aur=0
  if ((${#sel_aur[@]})); then
    if [[ "$DRY" == "1" ]]; then ok "[dry] aur: ${sel_aur[*]}"; else
      if [[ -z "$AURH" ]]; then warn "No AUR helper found. Skipping AUR."; else
        if run_with_pgp_retry "Installing AUR packages" "$AURH" -S --needed --noconfirm --noprogressbar "${sel_aur[@]}"; then
          success_aur=${#sel_aur[@]}
        else
          warn "AUR batch failed. Retrying individually."
          for p in "${sel_aur[@]}"; do
            if run_with_pgp_retry "aur $p" "$AURH" -S --needed --noconfirm --noprogressbar "$p"; then
              ((success_aur++))
            else
              ((fail_aur++)); err "[aur] $p"
            fi
          done
        fi
      fi
    fi
  fi

  # Flatpaks
  success_fp=0 fail_fp=0
  if ((${#sel_fp[@]})); then
    if [[ "$DRY" == "1" ]]; then ok "[dry] flatpak: ${sel_fp[*]}"; else
      if ! command -v flatpak >/dev/null 2>&1; then warn "flatpak not installed. Skipping Flatpaks."
      else
        for ref in "${sel_fp[@]}"; do
          remote="flathub"; app="$ref"; [[ "$ref" == *:* ]] && { remote="${ref%%:*}"; app="${ref#*:}"; }
          if spin "flatpak ${remote}:${app}" flatpak install -y --noninteractive "$remote" "$app"; then
            ((success_fp++))
          else
            ((fail_fp++)); err "[flatpak] ${remote}:${app}"
          fi
        done
      fi
    fi
  fi

  box "Summary"
  echo "Repo:    $success_repo ok, $fail_repo fail"
  echo "AUR:     $success_aur ok, $fail_aur fail"
  echo "Flatpak: $success_fp ok, $fail_fp fail"
}

# ── Menu actions ───────────────────────────────────────────────────────────────
menu(){
  while :; do
    box "BlendOS system.yaml ➜ Arch/CachyOS"
    load_cfg || true
    [[ -z "${YAML_SOURCE_TYPE:-}" || -z "${YAML_SOURCE:-}" ]] && first_run
    echo "Source: ${YAML_SOURCE_TYPE} → ${YAML_SOURCE} ${YAML_IN_REPO_PATH:+(${YAML_IN_REPO_PATH})}"
    action=$(choose "Install" "Dry run" "Update repo" "Edit YAML" "Change source" "View last log" "Quit")
    case "$action" in
      "Install")
        resolve_yaml; install_all 0 | tee "$LOG"
        ;;
      "Dry run")
        resolve_yaml; install_all 1 | tee "$LOG"
        ;;
      "Update repo")
        [[ "$YAML_SOURCE_TYPE" == "git" ]] && git_update || warn "Not a git source."
        ;;
      "Edit YAML")
        resolve_yaml
        ${EDITOR:-nano} "$yaml_path"
        ;;
      "Change source")
        first_run
        ;;
      "View last log")
        ${PAGER:-less} "$LOG"
        ;;
      "Quit") exit 0;;
    esac
  done
}

menu
