# Dotfile Symlinks Script

This guide documents the `scripts/dotfile-symlinks.sh` utility used to link (and selectively copy) configuration files from this repository into your home directory on Linux.

## Goals and Scope

- Keep dotfiles in version control under this repo
- Idempotently link them into `$HOME` / `$XDG_CONFIG_HOME`
- Support multiple Linux hosts and arbitrary clone locations
- Provide safe, readable output and a dry-run mode

> Note: This script targets GNU/Linux (GNU coreutils). Some flags differ on macOS/BSD and are not officially supported here.

## What it does

- Detects the repository root based on the script path
- Resolves `$XDG_CONFIG_HOME` or defaults to `~/.config`
- Creates parent directories as needed
- Creates or updates symlinks with `ln -sfn` (does not dereference an existing destination link)
- Copies specific files with `cp -u` (only if newer)
- Skips operations when the source and destination resolve to the same path
- Provides clear, colorized output with icons

## Quick start

```bash
# Preview actions without applying changes
bash scripts/dotfile-symlinks.sh --dry-run

# Apply changes
bash scripts/dotfile-symlinks.sh
```

Disable colors:

```bash
NO_COLOR=1 bash scripts/dotfile-symlinks.sh --dry-run
```

## Options

- `--dry-run`, `-n`: Show intended actions without applying
- `--help`, `-h`: Print usage summary
- Environment: `NO_COLOR=1` disables colorized output

## Output legend

- 📁 ensure dir: create parent directory (no-op if it exists)
- 🔗 link: create/update a symbolic link
- 📄 copy: copy a file (only if newer)
- ⏭ Skip: operation skipped (already up to date or same file)
- ⚠ Warn: source missing or potential caveat
- 🧪 DRY-RUN: run completed without changes
- ✔ Completed: run finished and applied changes

## Editing the mappings

Open `scripts/dotfile-symlinks.sh` and edit the mapping list at the bottom:

```bash
ensure_dir_and_link   "$REPO_ROOT/config/atuin/config.toml"   "$XDG_CONFIG_HOME/atuin/config.toml"
ensure_dir_and_copy   "$REPO_ROOT/config/aichat/config.yaml"  "$XDG_CONFIG_HOME/aichat/config.yaml"
# ... add more mappings here
```

Guidelines:

- Prefer linking directories for tool configs that are repo-managed as a tree (e.g., `fastfetch/`)
- Prefer copying for files that tools may frequently rewrite locally (e.g., caches or machine-specific tokens)
- Always verify the source path exists; the script will warn if it doesn’t

## Relative vs absolute links

The script currently uses absolute links for simplicity and clarity. If you frequently relocate your home directory or the repository, consider adding a `--relative` option to use `ln -r` (GNU `ln` only). This is not enabled by default.

## Troubleshooting

- "same file" when copying: The script now checks canonical paths and skips the copy if they’re the same.
- Destination already exists: `ln -sfn` replaces files/symlinks and updates links correctly; parent directories are created as needed.
- Source missing: The script prints a warning and still attempts to create a symlink (which may be dangling). Run again after the source exists.
- Colors look odd: Set `NO_COLOR=1` to disable ANSI colors.

## Safety notes

- The script never recursively removes directories. It only creates directories (with `mkdir -p`) and writes files/links to specified destinations.
- Be mindful when adding new mappings that point outside your home directory; those may require `sudo` and are not recommended here.

## Extending the script

Potential enhancements:

- `--relative`: create relative symlinks with `ln -r`
- `--only <name>`: run a subset of mappings
- `--verbose`: show underlying commands in addition to friendly output

Contributions welcome. Keep Linux portability in mind and avoid macOS/BSD-specific flags.
