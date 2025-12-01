#!/usr/bin/env bash
# Example script showing how to use the OS detection script

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the OS detection script
source "$SCRIPT_DIR/detect-os.sh"

# Now you can use all the exported variables and functions

echo "Example: Using OS detection in your script"
echo ""

# Example 1: Display OS information
print_os_info

echo ""
echo "Example Usage Patterns:"
echo ""

# Example 2: Conditional logic based on OS type
echo "1. Conditional logic based on OS:"
if [[ "$OS_TYPE" == "linux" ]]; then
    echo "   ✓ Running on Linux"
elif [[ "$OS_TYPE" == "macos" ]]; then
    echo "   ✓ Running on macOS"
fi

echo ""

# Example 3: Conditional logic based on distribution
echo "2. Distribution-specific logic:"
case "$OS_DISTRO" in
    arch|manjaro|endeavouros|blendos|cachyos|artix|arcolinux)
        echo "   ✓ Arch-based system detected"
        if [[ -n "$AUR_HELPER" ]]; then
            echo "   ✓ AUR helper available: $AUR_HELPER"
        fi
        ;;
    ubuntu|debian)
        echo "   ✓ Debian-based system detected"
        ;;
    fedora|rhel|centos)
        echo "   ✓ Red Hat-based system detected"
        ;;
esac

echo ""

# Example 4: Install packages using the helper function
echo "3. Installing packages (commented out for safety):"
echo "   # install_packages git vim curl"
echo "   This would run: $PKG_INSTALL_CMD git vim curl"

echo ""

# Example 5: Check for specific package manager
echo "4. Package manager checks:"
if [[ "$PKG_MANAGER" == "pacman" ]]; then
    echo "   ✓ Using pacman package manager"
    echo "   Install command: $PKG_INSTALL_CMD"
fi

echo ""

# Example 6: WSL detection
echo "5. WSL detection:"
if [[ "$IS_WSL" == "true" ]]; then
    echo "   ✓ Running inside WSL"
else
    echo "   ✗ Not running in WSL"
fi

echo ""

# Example 7: Version-based logic
echo "6. Version information:"
echo "   Distribution: $OS_DISTRO"
echo "   Version: $OS_VERSION"
echo "   Codename: $OS_CODENAME"

echo ""
echo "All available environment variables:"
echo "  - OS_TYPE: $OS_TYPE"
echo "  - OS_DISTRO: $OS_DISTRO"
echo "  - OS_VERSION: $OS_VERSION"
echo "  - OS_CODENAME: $OS_CODENAME"
echo "  - PKG_MANAGER: $PKG_MANAGER"
echo "  - PKG_INSTALL_CMD: $PKG_INSTALL_CMD"
echo "  - PKG_UPDATE_CMD: $PKG_UPDATE_CMD"
echo "  - PKG_UPGRADE_CMD: $PKG_UPGRADE_CMD"
echo "  - IS_WSL: $IS_WSL"
if [[ -n "$AUR_HELPER" ]]; then
    echo "  - AUR_HELPER: $AUR_HELPER"
fi
