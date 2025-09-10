My dotfiles to be linked into the home folder with GNU Stow.

## Configs in this repo:
- `aichat`
- `atuin`
- `burn-my-windows`
- `gsnap`
- `guake`
- `kitty`
- `starship`
- `.bash.rc`
- `BlendOS system.yaml`

## Package Installation Scripts

### `install-arch-packages.sh`

Enhanced package installer with the following new features:

**🚀 New Features:**
- **Automatic AUR Helper Installation**: Automatically installs `paru` if neither `yay` nor `paru` are available
- **Mirror Optimization**: Uses `reflector` to automatically select the fastest mirrors for better download speeds
- **Repository Setup**: Automatically configures Chaotic-AUR and multilib repositories
- **Rich Terminal Output**: Compact, colorful output with progress bars (similar to `nala`)
- **Package Filtering**: New options to install only specific package types

**📦 Installation Options:**
- `--dry-run` - Preview what would be installed without making changes
- `--only-aur` - Install only AUR packages
- `--only-chaotic` - Install only Chaotic-AUR packages  
- `--skip-aur` - Skip AUR packages installation
- `--skip-chaotic` - Skip Chaotic-AUR packages installation
- `--verbose` - Enable detailed logging

**🔧 Automatic Setup:**
- Installs missing AUR helpers (`paru` preferred)
- Optimizes package mirrors using `reflector` 
- Configures Chaotic-AUR repository with keyring
- Enables multilib repository if needed
- Creates detailed installation logs

**Usage Example:**
```bash
# Preview all packages to be installed
./install-arch-packages.sh --dry-run

# Install all packages with optimizations
./install-arch-packages.sh

# Install only AUR packages
./install-arch-packages.sh --only-aur
```

