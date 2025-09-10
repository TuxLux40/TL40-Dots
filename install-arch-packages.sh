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
# Author: TuxLux40

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/install-custom-packages.py"
YAML_FILE="$SCRIPT_DIR/system.yaml"

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
    print_info "Checking requirements..."
    
    # Check if Python script exists
    if [[ ! -f "$PYTHON_SCRIPT" ]]; then
        print_error "Python script not found: $PYTHON_SCRIPT"
        exit 1
    fi
    
    # Check if YAML file exists
    if [[ ! -f "$YAML_FILE" ]]; then
        print_error "YAML file not found: $YAML_FILE"
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

setup_mirrors() {
    print_info "Checking and optimizing package mirrors..."
    
    # Check if we're in an environment where we can modify mirrors
    if ! command -v pacman &> /dev/null; then
        print_warning "pacman not available - cannot setup mirrors"
        return 1
    fi
    
    # Check if reflector is available
    if command -v reflector &> /dev/null; then
        print_info "Using reflector to select fastest mirrors..."
        sudo reflector --country Germany,Austria,Switzerland --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        print_success "Mirrors optimized with reflector"
    else
        # Install reflector if not available
        print_info "Installing reflector for mirror optimization..."
        if sudo pacman -S --needed --noconfirm reflector; then
            print_info "Selecting fastest mirrors..."
            sudo reflector --country Germany,Austria,Switzerland --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
            print_success "Mirrors optimized with reflector"
        else
            print_warning "Could not install reflector. Using default mirrors."
        fi
    fi
    
    # Update package databases with new mirrors
    print_info "Updating package databases..."
    if sudo pacman -Sy; then
        print_success "Package databases updated"
    else
        print_warning "Failed to update package databases"
    fi
}

check_and_setup_repositories() {
    print_info "Checking repository configuration..."
    
    # Check if we're in an environment where we can modify repositories
    if ! command -v pacman &> /dev/null; then
        print_warning "pacman not available - cannot setup repositories"
        return 1
    fi
    
    # Check if multilib is enabled
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        print_info "Enabling multilib repository..."
        sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
        print_success "Multilib repository enabled"
        
        # Update package databases after enabling multilib
        sudo pacman -Sy
    else
        print_info "Multilib repository already enabled"
    fi
    
    # Check and setup Chaotic-AUR
    if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
        print_info "Setting up Chaotic-AUR repository..."
        
        # Install chaotic keyring and mirrorlist
        if ! pacman -Qi chaotic-keyring &> /dev/null; then
            print_info "Installing Chaotic-AUR keyring..."
            sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
            sudo pacman-key --lsign-key 3056513887B78AEB
            sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.xz'
        fi
        
        if ! pacman -Qi chaotic-mirrorlist &> /dev/null; then
            print_info "Installing Chaotic-AUR mirrorlist..."
            sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.xz'
        fi
        
        # Add Chaotic-AUR to pacman.conf
        echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
        print_success "Chaotic-AUR repository configured"
        
        # Update package databases
        sudo pacman -Sy
    else
        print_info "Chaotic-AUR repository already configured"
    fi
}

check_and_install_aur_helper() {
    # Check for existing AUR helpers
    if command -v yay &> /dev/null; then
        print_success "Found AUR helper: yay"
        return 0
    elif command -v paru &> /dev/null; then
        print_success "Found AUR helper: paru"
        return 0
    else
        print_warning "No AUR helper found."
        
        # Check if we're in an environment where we can install packages
        if ! command -v pacman &> /dev/null; then
            print_warning "pacman not available - cannot auto-install AUR helper"
            print_info "Please install yay or paru manually in your Arch environment"
            return 1
        fi
        
        print_info "Installing paru..."
        
        # Check if we have the necessary tools to build AUR packages
        if ! command -v git &> /dev/null || ! pacman -Qi base-devel &> /dev/null; then
            print_info "Installing build dependencies..."
            if ! sudo pacman -S --needed --noconfirm git base-devel; then
                print_error "Failed to install build dependencies"
                return 1
            fi
        fi
        
        # Install paru
        print_info "Cloning and building paru..."
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        if git clone https://aur.archlinux.org/paru.git; then
            cd paru
            if makepkg -si --noconfirm; then
                print_success "Successfully installed paru"
                cd "$SCRIPT_DIR"
                rm -rf "$temp_dir"
                return 0
            else
                print_error "Failed to build paru"
                cd "$SCRIPT_DIR"
                rm -rf "$temp_dir"
                return 1
            fi
        else
            print_error "Failed to clone paru repository"
            cd "$SCRIPT_DIR"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
}

main() {
    local dry_run=false
    local verbose=false
    local yaml_file="$YAML_FILE"
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
                python_args+=(--yaml "$2")
                shift 2
                ;;
            --skip-aur)
                python_args+=(--skip-aur)
                shift
                ;;
            --skip-chaotic)
                python_args+=(--skip-chaotic)
                shift
                ;;
            --only-aur)
                python_args+=(--only-aur)
                shift
                ;;
            --only-chaotic)
                python_args+=(--only-chaotic)
                shift
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
    
    # Check requirements
    check_requirements
    
    # Setup mirrors and repositories
    if ! $dry_run; then
        setup_mirrors
        check_and_setup_repositories
    else
        print_info "[DRY-RUN] Would setup mirrors and repositories"
    fi
    
    # Check and install AUR helper if needed
    if ! check_and_install_aur_helper && ! $dry_run; then
        print_warning "AUR helper installation failed. AUR packages will be skipped."
    fi
    
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