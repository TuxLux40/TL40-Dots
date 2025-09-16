#!/bin/bash
#
# TL40-BOS Custom Package Installer
# 
# This script installs custom packages from system.yaml, excluding core packages
# that are already included in CachyOS or are blendOS-specific. It handles AUR
# and Chaotic packages separately and logs any installation failures.
#
# Usage: ./install-custom-packages.sh [OPTIONS]
#
# Work in progress - use at your own risk
#------------------------------------------------------------------------------

set -euo pipefail

# Script and repo directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PYTHON_SCRIPT="$SCRIPT_DIR/install-custom-packages.py"
# Default YAML lives under pkg_lists in the repo
YAML_DEFAULT="$REPO_ROOT/pkg_lists/system.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
TL40-BOS Custom Package Installer

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -n, --dry-run   Show what would be installed without actually installing
    -v, --verbose   Enable verbose logging
    -y, --yaml FILE Use custom YAML file (default: system.yaml)
    --skip-aur      Skip AUR packages installation
    --skip-chaotic  Skip Chaotic-AUR packages installation
    --only-aur      Install only AUR packages
    --only-chaotic  Install only Chaotic-AUR packages

DESCRIPTION:
    This script parses the system.yaml file and installs custom packages while
    excluding core packages that are already included in CachyOS or are 
    blendOS-specific. It handles AUR and Chaotic packages separately and logs
    any installation failures.

EXAMPLES:
    # Dry run to see what would be installed
    $(basename "$0") --dry-run
    
    # Install all custom packages with verbose output
    $(basename "$0") --verbose
    
    # Install only AUR packages
    $(basename "$0") --only-aur
    
    # Skip AUR packages (install regular and Chaotic only)
    $(basename "$0") --skip-aur

NOTES:
    - Requires sudo privileges for package installation
    - Creates install log in current directory (package_install.log)
    - Requires yay or paru for AUR packages
    - Automatically sets up Chaotic-AUR repository if needed

EOF
}

check_requirements() {
    local yaml_path="$1"
    print_info "Checking requirements..."

    # Check if Python script exists
    if [[ ! -f "$PYTHON_SCRIPT" ]]; then
        print_error "Python script not found: $PYTHON_SCRIPT"
        exit 1
    fi

    # Check if YAML file exists (selected or default)
    if [[ ! -f "$yaml_path" ]]; then
        print_error "YAML file not found: $yaml_path"
        exit 1
    fi

    # Check if Python3 is available
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is required but not installed"
        exit 1
    fi

    # Check if PyYAML is available
    if ! python3 -c "import yaml" 2>/dev/null; then
        print_error "PyYAML is required. Install with: sudo pacman -S python-yaml"
        exit 1
    fi

    print_success "All requirements met"
}

check_aur_helper() {
    if command -v yay &> /dev/null; then
        print_info "Found AUR helper: yay"
        return 0
    elif command -v paru &> /dev/null; then
        print_info "Found AUR helper: paru"
        return 0
    else
        print_warning "No AUR helper (yay/paru) found. AUR packages will be skipped."
        return 1
    fi
}

main() {
    local dry_run=false
    local verbose=false
    local yaml_file="$YAML_DEFAULT"
    local python_args=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--dry-run)
                dry_run=true
                python_args+=(--dry-run)
                shift
                ;;
            -v|--verbose)
                verbose=true
                python_args+=(--verbose)
                shift
                ;;
            -y|--yaml)
                if [[ $# -lt 2 ]]; then
                    print_error "Option --yaml requires an argument"
                    exit 1
                fi
                yaml_file="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
    
    print_info "TL40-BOS Custom Package Installer"
    print_info "================================="
    
    # Check requirements with the resolved YAML path
    check_requirements "$yaml_file"
    
    # Check for AUR helper
    check_aur_helper
    
    # Show what we're doing
    if $dry_run; then
        print_info "Running in DRY-RUN mode - no packages will be installed"
    else
        print_warning "This will install packages on your system"
        print_info "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
        sleep 5
    fi
    
    print_info "Using YAML file: $yaml_file"
    print_info "Log file: $(pwd)/package_install.log"
    
    # Run the Python script
    print_info "Starting package installation..."
    
    # Always pass the resolved YAML path to Python
    python_args+=(--yaml "$yaml_file")
    if python3 "$PYTHON_SCRIPT" "${python_args[@]}"; then
        print_success "Package installation completed successfully!"
        if [[ -f "package_install.log" ]]; then
            print_info "Detailed log available in: package_install.log"
        fi
    else
        print_error "Package installation failed. Check package_install.log for details."
        exit 1
    fi
}

# Run main function with all arguments
main "$@"