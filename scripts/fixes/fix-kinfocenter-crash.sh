#!/bin/bash
# Fix for KInfoCenter crash with kcm_about-distro module
# Issue: KInfoCenter crashes when loading the "About Distro" module (KDE 6.5.5)
# Solution: Disable the problematic module by renaming it

set -e

MODULE_PATH="/usr/lib/qt6/plugins/plasma/kcms/kcm_about-distro.so"
BACKUP_PATH="${MODULE_PATH}.disabled"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_module() {
    if [[ -f "$MODULE_PATH" ]]; then
        echo "enabled"
    elif [[ -f "$BACKUP_PATH" ]]; then
        echo "disabled"
    else
        echo "missing"
    fi
}

disable_module() {
    local status=$(check_module)
    
    case "$status" in
        "enabled")
            print_warning "Disabling kcm_about-distro module..."
            sudo mv "$MODULE_PATH" "$BACKUP_PATH"
            print_status "Module disabled successfully"
            print_status "KInfoCenter should now work without crashes"
            ;;
        "disabled")
            print_status "Module is already disabled"
            ;;
        "missing")
            print_error "Module not found in expected location"
            exit 1
            ;;
    esac
}

enable_module() {
    local status=$(check_module)
    
    case "$status" in
        "disabled")
            print_warning "Enabling kcm_about-distro module..."
            sudo mv "$BACKUP_PATH" "$MODULE_PATH"
            print_status "Module enabled successfully"
            print_warning "Warning: This may cause KInfoCenter to crash again"
            ;;
        "enabled")
            print_status "Module is already enabled"
            ;;
        "missing")
            print_error "Module backup not found"
            exit 1
            ;;
    esac
}

status_module() {
    local status=$(check_module)
    
    echo "KInfoCenter About-Distro Module Status:"
    echo "----------------------------------------"
    
    case "$status" in
        "enabled")
            echo -e "Status: ${RED}ENABLED${NC} (may cause crashes)"
            echo "Path: $MODULE_PATH"
            ;;
        "disabled")
            echo -e "Status: ${GREEN}DISABLED${NC} (workaround active)"
            echo "Path: $BACKUP_PATH"
            ;;
        "missing")
            echo -e "Status: ${RED}MISSING${NC}"
            echo "The module could not be found"
            ;;
    esac
    
    echo ""
    echo "Related packages:"
    pacman -Q kinfocenter plasma-workspace qt6-base 2>/dev/null || true
}

show_help() {
    cat << EOF
KInfoCenter Crash Fix - kcm_about-distro module manager

Usage: $(basename "$0") [COMMAND]

Commands:
    disable     Disable the kcm_about-distro module (prevents crashes)
    enable      Enable the kcm_about-distro module
    status      Show current module status
    help        Show this help message

Description:
    This script manages the kcm_about-distro module that causes KInfoCenter
    to crash in KDE Plasma 6.5.5 on certain distributions including CachyOS.
    
    The crash occurs when KInfoCenter tries to load distribution information
    and encounters an issue in the about-distro KCM module, resulting in a
    Qt abort() call.

Example:
    sudo $(basename "$0") disable    # Disable the problematic module
    $(basename "$0") status          # Check current status
    sudo $(basename "$0") enable     # Re-enable when fixed upstream

EOF
}

# Main
case "${1:-}" in
    disable)
        disable_module
        ;;
    enable)
        enable_module
        ;;
    status)
        status_module
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Usage: $(basename "$0") {disable|enable|status|help}"
        echo "Run '$(basename "$0") help' for more information"
        exit 1
        ;;
esac
