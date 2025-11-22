# Wiki Auto-Sync Setup

Automatically sync repo documentation to wiki while keeping personal troubleshooting guides manually editable.

## Concept

**Two types of documentation:**

1. **Repo Docs** (in `TL40-Dots/docs/`):

   - `scripts.md` - Script documentation
   - `config.md` - Config structure
   - `dotfiles.md` - Symlink management
   - `os-detection.md` - OS detection utility
   - → Automatically synced to wiki

2. **Personal Guides** (wiki only):
   - `yubikey-sudo.md` - YubiKey setup
   - `secureboot.md` - Secure Boot
   - `borg-backup.md` - Backup commands
   - `git-setup.md`, `git.md` - Git config
   - `Home.md` - Navigation
   - → Stay in wiki only, NOT overwritten

## Setup Steps

### 1. Copy workflow to main repo

```bash
# In TL40-Dots repository:
mkdir -p .github/workflows
cp ../TL40-Dots.wiki/.github/workflows/sync-wiki.yml .github/workflows/
```

### 2. Create docs folder in main repo

```bash
# In TL40-Dots repository:
mkdir -p docs

# Copy these files from wiki to main repo:
cp ../TL40-Dots.wiki/scripts.md docs/
cp ../TL40-Dots.wiki/config.md docs/
cp ../TL40-Dots.wiki/dotfiles.md docs/
cp ../TL40-Dots.wiki/os-detection.md docs/
```

### 3. Git Structure```

```
TL40-Dots/                          # Main Repository
├── docs/
│   ├── scripts.md                  # Auto-sync → Wiki
│   ├── config.md                   # Auto-sync → Wiki
│   ├── dotfiles.md                 # Auto-sync → Wiki
│   └── os-detection.md             # Auto-sync → Wiki
└── .github/workflows/
    └── sync-wiki.yml

TL40-Dots.wiki/                     # Wiki Repository
├── scripts.md                      # ← Auto-updated from main
├── config.md                       # ← Auto-updated from main
├── dotfiles.md                     # ← Auto-updated from main
├── os-detection.md                 # ← Auto-updated from main
├── yubikey-sudo.md                 # Manually editable
├── secureboot.md                   # Manually editable
├── borg-backup.md                  # Manually editable
├── git-setup.md                    # Manually editable
├── git.md                          # Manually editable
└── Home.md                         # Manually editable
```

## Workflow

### Update repo docs:

```bash
cd ~/Projects/TL40-Dots
vim docs/scripts.md
git add docs/
git commit -m "Update script docs"
git push
# → Wiki automatically updated
```

### Update personal guides:

```bash
cd ~/git/TL40-Dots.wiki
vim yubikey-sudo.md
git add .
git commit -m "Update YubiKey guide"
git push
# → Direct to wiki, no auto-sync needed
```

## Customization

To auto-sync additional files, edit `.github/workflows/sync-wiki.yml`:

```yaml
- name: Sync repo documentation to wiki
  run: |
    # Add more files:
    cp -f docs/scripts.md wiki-repo/ 2>/dev/null || true
    cp -f docs/config.md wiki-repo/ 2>/dev/null || true
    cp -f docs/new-file.md wiki-repo/ 2>/dev/null || true
```

````

## Workflow

### Repo-Docs aktualisieren:

```bash
cd ~/Projects/TL40-Dots
vim docs/scripts.md
git add docs/
git commit -m "Update script docs"
git push
# → Wiki wird automatisch aktualisiert
````

### Personal Guides aktualisieren:

```bash
cd ~/git/TL40-Dots.wiki
vim yubikey-sudo.md
git add .
git commit -m "Update YubiKey guide"
git push
# → Direkt im Wiki, kein Auto-Sync nötig
```

## Anpassung

Falls du andere Dateien auto-syncen willst, editiere in `.github/workflows/sync-wiki.yml`:

```yaml
- name: Sync repo documentation to wiki
  run: |
    # Füge weitere Dateien hinzu:
    cp -f docs/scripts.md wiki-repo/ 2>/dev/null || true
    cp -f docs/config.md wiki-repo/ 2>/dev/null || true
    cp -f docs/neue-datei.md wiki-repo/ 2>/dev/null || true
```

````

### Personal Guides aktualisieren:
```bash
cd ~/git/TL40-Dots.wiki
vim yubikey-sudo.md
git add .
git commit -m "Update YubiKey guide"
git push
# → Direkt im Wiki, kein Auto-Sync nötig
````

## Anpassung

Falls du andere Dateien auto-syncen willst, editiere in `.github/workflows/sync-wiki.yml`:

```yaml
- name: Sync repo documentation to wiki
  run: |
    # Füge weitere Dateien hinzu:
    cp -f docs/scripts.md wiki-repo/ 2>/dev/null || true
    cp -f docs/config.md wiki-repo/ 2>/dev/null || true
    cp -f docs/neue-datei.md wiki-repo/ 2>/dev/null || true
```

**Option A: docs/ folder**

```
TL40-Dots/
├── docs/
│   ├── Home.md
│   ├── yubikey-sudo.md
│   ├── secureboot.md
│   └── ...
```

**Option B: wiki/ folder**

```
TL40-Dots/
├── wiki/
│   ├── Home.md
│   ├── yubikey-sudo.md
│   ├── secureboot.md
│   └── ...
```

### 3. How it works

1. You edit `.md` files in `docs/` or `wiki/` in the main repo
2. Push to `main` or `master` branch
3. GitHub Action triggers automatically
4. Files are synced to the wiki repository
5. Changes appear in the GitHub Wiki UI

### 4. Customization

Edit the `paths:` section in the workflow to trigger on different files:

```yaml
paths:
  - "docs/**" # Trigger on docs/ changes
  - "wiki/**" # Or wiki/ changes
  - "README.md" # Include specific files
```

## Alternative: Manual Sync

If you prefer working directly in the wiki repo (like now), you can skip the action and just:

```bash
cd ~/git/TL40-Dots.wiki
git add .
git commit -m "Update docs"
git push
```

The wiki updates immediately on push.

## Note

GitHub wikis are separate Git repos at `https://github.com/TuxLux40/TL40-Dots.wiki.git`. You can clone and push to them directly, or use the action to sync from main repo.
