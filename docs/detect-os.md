# OS Detection Script Documentation

## Overview

The `detect-os.sh` script provides comprehensive operating system and package manager detection for use across all your shell scripts. It exports environment variables and helper functions that make writing cross-platform scripts much easier.

## Usage

### Sourcing the Script

To use the OS detection in your scripts, simply source it:

```bash
#!/usr/bin/env bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the OS detection script
source "$SCRIPT_DIR/detect-os.sh"

# Now all variables and functions are available
echo "Running on: $OS_DISTRO"
```

### Running Standalone

You can also run the script directly to see detected information:

```bash
./detect-os.sh
```

## Exported Variables

After sourcing the script, these variables are available:

| Variable          | Description                   | Example Values                      |
| ----------------- | ----------------------------- | ----------------------------------- |
| `OS_TYPE`         | Operating system type         | `linux`, `macos`, `windows`         |
| `OS_DISTRO`       | Linux distribution or OS name | `ubuntu`, `arch`, `fedora`, `macos` |
| `OS_VERSION`      | Version number                | `22.04`, `rolling`, `14.5`          |
| `OS_CODENAME`     | Release codename              | `jammy`, `Sonoma`, `unknown`        |
| `PKG_MANAGER`     | Package manager name          | `apt`, `pacman`, `dnf`, `brew`      |
| `PKG_INSTALL_CMD` | Full install command          | `sudo apt install -y`               |
| `PKG_UPDATE_CMD`  | Full update command           | `sudo apt update`                   |
| `PKG_UPGRADE_CMD` | Full upgrade command          | `sudo apt upgrade -y`               |
| `IS_WSL`          | Running in WSL                | `true`, `false`                     |
| `AUR_HELPER`      | AUR helper (Arch only)        | `paru`, `yay`, or empty             |

## Supported Operating Systems

### Linux Distributions

**Debian-based:**

- Ubuntu
- Debian
- Linux Mint
- Pop!\_OS
- Elementary OS
- Zorin OS
- Kali Linux

**Arch-based:**

- Arch Linux
- Manjaro
- EndeavourOS
- Garuda Linux
- ArcoLinux
- Artix Linux
- CachyOS
- BlendOS

**Red Hat-based:**

- Fedora
- RHEL (Red Hat Enterprise Linux)
- CentOS
- Rocky Linux
- AlmaLinux

**Other:**

- openSUSE / SLES
- Alpine Linux
- Gentoo
- Void Linux
- NixOS
- Solus

### macOS

Supports all recent macOS versions with automatic version name detection (Sequoia, Sonoma, Ventura, etc.)

### Windows

Supports Windows environments through:

- WSL (Windows Subsystem for Linux)
- MSYS2/MinGW
- Cygwin

## Available Functions

### `print_os_info()`

Displays all detected OS information in a formatted table.

```bash
source detect-os.sh
print_os_info
```

### `check_package_manager()`

Checks if a valid package manager was detected. Returns 0 on success, 1 on failure.

```bash
if check_package_manager; then
    echo "Package manager available"
fi
```

### `install_packages()`

Installs packages using the detected package manager.

```bash
install_packages git curl vim
# Runs: sudo pacman -S --noconfirm git curl vim (on Arch)
# Runs: sudo apt install -y git curl vim (on Ubuntu)
```

## Example Use Cases

### 1. Install Dependencies Based on OS

```bash
source detect-os.sh

case "$OS_DISTRO" in
    arch|manjaro|cachyos)
        install_packages base-devel git
        ;;
    ubuntu|debian)
        install_packages build-essential git
        ;;
    fedora)
        install_packages @development-tools git
        ;;
esac
```

### 2. Handle Platform-Specific Paths

```bash
source detect-os.sh

if [[ "$OS_TYPE" == "macos" ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/myapp"
else
    CONFIG_DIR="$HOME/.config/myapp"
fi
```

### 3. Check for WSL

```bash
source detect-os.sh

if [[ "$IS_WSL" == "true" ]]; then
    echo "Running in WSL, adjusting network settings..."
fi
```

### 4. Use AUR Helper on Arch

```bash
source detect-os.sh

if [[ -n "$AUR_HELPER" ]]; then
    $AUR_HELPER -S --noconfirm package-from-aur
fi
```

### 5. Conditional Features

```bash
source detect-os.sh

# Enable systemd features only on supported distros
if [[ "$PKG_MANAGER" != "apk" ]]; then
    sudo systemctl enable myservice
fi
```

## Integration with Existing Scripts

To integrate with your existing scripts in the repository:

1. **Add the source line** at the beginning of your script:

   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/detect-os.sh"
   ```

2. **Replace hardcoded package manager commands** with variables:

   ```bash
   # Before:
   sudo pacman -S --noconfirm git

   # After:
   install_packages git
   # or
   $PKG_INSTALL_CMD git
   ```

3. **Add distribution checks** where needed:
   ```bash
   if [[ "$OS_DISTRO" == "arch" ]]; then
       # Arch-specific logic
   fi
   ```

## Examples

See `example-os-usage.sh` for a comprehensive demonstration of all features.

## Error Handling

The script will:

- Log warnings for unknown distributions (but continue)
- Log errors for completely unknown OS types
- Export "unknown" or "none" for undetected values
- Return appropriate exit codes from functions

## Notes

- The script uses `bash` and may not work in pure POSIX shell
- Requires `/etc/os-release` for modern Linux detection
- Falls back to older detection methods for legacy systems
- Color output can be disabled by modifying the color variables
- WSL detection works by checking `/proc/version` for "microsoft"

## Contributing

To add support for a new distribution:

1. Add the distribution ID to the appropriate case statement in `detect_package_manager()`
2. Define the package manager commands
3. Test on the target distribution
4. Update this documentation
