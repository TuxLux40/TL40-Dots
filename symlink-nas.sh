#!/usr/bin/env bash
# Symlink NAS folders into corresponding XDG user dirs.
# Idempotent: safe to re-run. Never overwrites existing non-symlink entries.

set -euo pipefail

NAS="${NAS:-$HOME/nas}"
DRY_RUN=0
FORCE=0

usage() {
    cat <<EOF
Usage: $0 [--dry-run] [--force] [--nas PATH]

  --dry-run  Print actions, do nothing.
  --force    Replace existing symlinks even if they point elsewhere.
             Never touches real files/dirs.
  --nas      NAS mount root (default: \$HOME/nas).
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --force)   FORCE=1;   shift ;;
        --nas)     NAS="$2";  shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
    esac
done

# Mapping format: "<nas relative path>|<target dir>|<link name>"
#
#   <nas relative path>  Path under $NAS (default: ~/nas) pointing at the source
#                        folder on the NAS. Both top-level shares (e.g. "music")
#                        and subpaths under "home/" (the personal share) are fine.
#   <target dir>         Local directory the symlink will be created in. Normally
#                        one of the XDG user dirs defined in ~/.config/user-dirs.dirs
#                        (Documents, Pictures, Music, Videos, Downloads).
#   <link name>          Basename of the symlink inside <target dir>. Convention
#                        is "NAS-<source>" so NAS content is clearly separated
#                        from local files and never collides with existing names.
#
# Rationale for the groupings below:
#   - The NAS has BOTH shared top-level dirs (Photos, music, movies, ...) AND
#     a personal "home/" share that contains another layer of content
#     (home/Photos, home/Music, home/documents, ...). Both get their own link
#     so nothing is hidden and the original structure stays inspectable.
#   - Links are created INSIDE the XDG dirs (not replacing them) because those
#     dirs already hold local files and are referenced by desktop apps, file
#     managers and xdg-open.
MAPPINGS=(
    # --- Documents -------------------------------------------------------
    # Personal documents share (scans, PDFs, working docs, etc.).
    "home/documents|$HOME/Documents|NAS-documents"
    # Ebook library (Calibre-style, one dir per author).
    "ebooks|$HOME/Documents|NAS-ebooks"

    # --- Pictures --------------------------------------------------------
    # Shared family/household photo library at the top of the NAS — the
    # "-shared" suffix distinguishes it from the personal one below.
    "Photos|$HOME/Pictures|NAS-Photos-shared"
    # Family photos — the curated, long-term photo archive.
    "home/Photos|$HOME/Pictures|NAS-Photos"
    # Downloaded / incidental pictures: social media saves, profile pics,
    # screenshots, image references. Deliberately kept separate from the
    # family photo archive above so backups/galleries stay clean.
    "home/pics|$HOME/Pictures|NAS-pics"

    # --- Music -----------------------------------------------------------
    # Main music library (shared, consumed by Jellyfin/Navidrome/etc.).
    "music|$HOME/Music|NAS-music"
    # Audiobooks live under Music so local audio players find them; move to
    # ~/Documents if a dedicated audiobook player is used instead.
    "audiobooks|$HOME/Music|NAS-audiobooks"
    # Personal music folder under the home share — kept separate from the
    # shared "music" library to avoid merging personal rips/downloads in.
    "home/Music|$HOME/Music|NAS-Music-personal"

    # --- Videos ----------------------------------------------------------
    # Full movie library (shared).
    "movies|$HOME/Videos|NAS-movies"
    # Short video clips / recordings — separate from movies on purpose so
    # media scanners don't treat them as films.
    "clips|$HOME/Videos|NAS-clips"

    # --- Downloads -------------------------------------------------------
    # NAS-side downloads inbox (e.g. things grabbed by a headless downloader
    # on the NAS itself). Local ~/Downloads stays the primary browser target.
    "home/downloads|$HOME/Downloads|NAS-downloads"
)

run() {
    if (( DRY_RUN )); then
        printf '[dry] %s\n' "$*"
    else
        printf '      %s\n' "$*"
        "$@"
    fi
}

# Sanity: NAS mounted?
if ! mountpoint -q "$NAS" 2>/dev/null && [[ ! -d "$NAS" ]]; then
    echo "error: NAS root '$NAS' not a directory / not mounted" >&2
    exit 1
fi
if [[ -z "$(ls -A "$NAS" 2>/dev/null)" ]]; then
    echo "error: NAS root '$NAS' is empty — mounted?" >&2
    exit 1
fi

created=0; skipped=0; missing=0; replaced=0

for entry in "${MAPPINGS[@]}"; do
    IFS='|' read -r src_rel target_dir link_name <<< "$entry"
    src="$NAS/$src_rel"
    dst="$target_dir/$link_name"

    if [[ ! -e "$src" ]]; then
        echo "skip  (missing on NAS): $src_rel"
        missing=$((missing+1))
        continue
    fi

    if [[ ! -d "$target_dir" ]]; then
        run mkdir -p "$target_dir"
    fi

    if [[ -L "$dst" ]]; then
        current="$(readlink "$dst")"
        if [[ "$current" == "$src" ]]; then
            echo "ok    $dst -> $src"
            skipped=$((skipped+1))
            continue
        fi
        if (( FORCE )); then
            run rm "$dst"
            run ln -s "$src" "$dst"
            echo "repl  $dst -> $src (was: $current)"
            replaced=$((replaced+1))
            continue
        fi
        echo "warn  $dst already symlink to $current (use --force to replace)" >&2
        skipped=$((skipped+1))
        continue
    fi

    if [[ -e "$dst" ]]; then
        echo "warn  $dst exists as real file/dir — refuse to clobber" >&2
        skipped=$((skipped+1))
        continue
    fi

    run ln -s "$src" "$dst"
    echo "new   $dst -> $src"
    created=$((created+1))
done

echo
printf 'Summary: %d created, %d replaced, %d already-correct, %d missing-on-NAS\n' \
    "$created" "$replaced" "$skipped" "$missing"
