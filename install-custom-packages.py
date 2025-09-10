#!/usr/bin/env python3
"""
Custom Package Installer for TL40-BOS

This script installs custom packages from system.yaml, excluding core packages
that are already included in CachyOS or are blendOS-specific. It handles AUR
and Chaotic packages separately and logs any installation failures.

Author: TuxLux40
"""

import yaml
import subprocess
import sys
import logging
import argparse
from pathlib import Path
from typing import List, Set, Dict, Tuple

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('package_install.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Core packages already included in CachyOS or system essentials
CORE_PACKAGES = {
    # Base system
    'bash', 'coreutils', 'util-linux', 'systemd', 'systemd-sysvcompat',
    'glibc', 'gcc-libs', 'linux-firmware', 'archlinux-keyring',
    
    # Bootloader and kernel essentials
    'grub', 'efibootmgr', 'os-prober', 'mkinitcpio',
    
    # Package management
    'pacman', 'base-devel',
    
    # Essential libraries
    'glib2', 'zlib', 'bzip2', 'xz',
    
    # Network essentials
    'networkmanager', 'openssh',
}

# BlendOS-specific packages to exclude
BLENDOS_PACKAGES = {
    'blend', 'blendr', 'blend-settings', 'filesystem-blend'
}

# CachyOS-specific packages (likely already installed in CachyOS)
CACHYOS_PACKAGES = {
    'linux-cachyos', 'linux-cachyos-headers'
}

class PackageInstaller:
    def __init__(self, yaml_path: str, dry_run: bool = False):
        self.yaml_path = Path(yaml_path)
        self.dry_run = dry_run
        self.failed_packages = []
        self.installed_packages = []
        
        if not self.yaml_path.exists():
            raise FileNotFoundError(f"YAML file not found: {yaml_path}")
    
    def load_yaml(self) -> Dict:
        """Load and parse the YAML file."""
        try:
            with open(self.yaml_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
            logger.info(f"Successfully loaded YAML from {self.yaml_path}")
            return data
        except Exception as e:
            logger.error(f"Failed to load YAML file: {e}")
            raise
    
    def filter_packages(self, packages: List[str]) -> List[str]:
        """Filter out core and blendOS-specific packages."""
        if not packages:
            return []
        
        # Remove packages that should be excluded
        exclude_packages = CORE_PACKAGES | BLENDOS_PACKAGES | CACHYOS_PACKAGES
        
        filtered = []
        for pkg in packages:
            if isinstance(pkg, str):
                pkg_name = pkg.strip()
                if pkg_name and pkg_name not in exclude_packages:
                    filtered.append(pkg_name)
                else:
                    logger.debug(f"Excluding package: {pkg_name}")
        
        return filtered
    
    def install_package_group(self, packages: List[str], package_type: str, 
                            install_command: List[str]) -> Tuple[List[str], List[str]]:
        """Install a group of packages and return success/failure lists."""
        if not packages:
            logger.info(f"No {package_type} packages to install")
            return [], []
        
        successful = []
        failed = []
        
        logger.info(f"Installing {len(packages)} {package_type} packages...")
        
        for package in packages:
            if self.dry_run:
                logger.info(f"[DRY RUN] Would install {package_type} package: {package}")
                successful.append(package)
                continue
            
            try:
                cmd = install_command + [package]
                logger.info(f"Installing {package_type} package: {package}")
                
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=300  # 5 minute timeout per package
                )
                
                if result.returncode == 0:
                    logger.info(f"Successfully installed: {package}")
                    successful.append(package)
                else:
                    logger.error(f"Failed to install {package}: {result.stderr}")
                    failed.append(package)
                    
            except subprocess.TimeoutExpired:
                logger.error(f"Timeout installing {package}")
                failed.append(package)
            except Exception as e:
                logger.error(f"Error installing {package}: {e}")
                failed.append(package)
        
        return successful, failed
    
    def setup_chaotic_repo(self) -> bool:
        """Ensure Chaotic-AUR repository is set up."""
        if self.dry_run:
            logger.info("[DRY RUN] Would setup Chaotic-AUR repository")
            return True
        
        try:
            # Check if chaotic keyring is installed
            result = subprocess.run(['pacman', '-Qi', 'chaotic-keyring'], 
                                  capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.info("Installing Chaotic-AUR keyring...")
                subprocess.run(['sudo', 'pacman', '-Sy', '--noconfirm', 'chaotic-keyring'], 
                             check=True)
                
            # Check if chaotic mirrorlist is installed
            result = subprocess.run(['pacman', '-Qi', 'chaotic-mirrorlist'], 
                                  capture_output=True, text=True)
                                  
            if result.returncode != 0:
                logger.info("Installing Chaotic-AUR mirrorlist...")
                subprocess.run(['sudo', 'pacman', '-Sy', '--noconfirm', 'chaotic-mirrorlist'], 
                             check=True)
            
            logger.info("Chaotic-AUR repository setup complete")
            return True
            
        except Exception as e:
            logger.error(f"Failed to setup Chaotic-AUR repository: {e}")
            return False
    
    def install_packages(self):
        """Main installation process."""
        data = self.load_yaml()
        
        # Extract package lists
        regular_packages = data.get('packages', [])
        aur_packages = data.get('aur-packages', [])
        
        # Separate Chaotic packages from regular packages
        # (based on the YAML structure, some Chaotic packages are in the main packages list)
        chaotic_packages = []
        filtered_regular_packages = []
        
        # Known Chaotic packages from the YAML comments
        known_chaotic = {
            'auto-cpufreq', 'betterbird-bin', 'chaotic-keyring', 'chaotic-mirrorlist',
            'debtap', 'gnome-shell-extension-blur-my-shell', 'gnome-shell-extension-dash-to-dock',
            'gnome-shell-extension-gsconnect-git', 'gnome-shell-extension-logo-menu',
            'gnome-shell-extension-space-bar-git', 'gnome-shell-extension-tiling-assistant',
            'go-mtpfs-git', 'google-chrome', 'handbrake-full', 'hardinfo2',
            'input-remapper-git', 'linux-cachyos', 'linux-cachyos-headers',
            'microsoft-edge-stable-bin', 'mediawriter', 'nautilus-code-git',
            'nautilus-open-any-terminal', 'refine', 'simple-mtpfs', 'tabby-bin',
            'visual-studio-code-bin', 'webapp-manager', 'waydroid', 'waydroid-image'
        }
        
        for pkg in regular_packages:
            if isinstance(pkg, str):
                pkg_name = pkg.strip()
                if pkg_name in known_chaotic:
                    chaotic_packages.append(pkg_name)
                else:
                    filtered_regular_packages.append(pkg_name)
        
        # Filter out excluded packages
        filtered_regular = self.filter_packages(filtered_regular_packages)
        filtered_chaotic = self.filter_packages(chaotic_packages)
        filtered_aur = self.filter_packages(aur_packages)
        
        logger.info(f"Package summary:")
        logger.info(f"  Regular packages: {len(filtered_regular)}")
        logger.info(f"  Chaotic packages: {len(filtered_chaotic)}")
        logger.info(f"  AUR packages: {len(filtered_aur)}")
        
        all_successful = []
        all_failed = []
        
        # Install regular packages with pacman
        if filtered_regular:
            success, failed = self.install_package_group(
                filtered_regular, 
                "regular",
                ['sudo', 'pacman', '-S', '--noconfirm']
            )
            all_successful.extend(success)
            all_failed.extend(failed)
        
        # Setup and install Chaotic packages
        if filtered_chaotic:
            if self.setup_chaotic_repo():
                success, failed = self.install_package_group(
                    filtered_chaotic,
                    "Chaotic",
                    ['sudo', 'pacman', '-S', '--noconfirm']
                )
                all_successful.extend(success)
                all_failed.extend(failed)
            else:
                logger.error("Skipping Chaotic packages due to repository setup failure")
                all_failed.extend(filtered_chaotic)
        
        # Install AUR packages (requires yay or another AUR helper)
        if filtered_aur:
            # Check if yay is available
            try:
                subprocess.run(['which', 'yay'], check=True, capture_output=True)
                aur_helper = 'yay'
            except subprocess.CalledProcessError:
                try:
                    subprocess.run(['which', 'paru'], check=True, capture_output=True)
                    aur_helper = 'paru'
                except subprocess.CalledProcessError:
                    logger.error("No AUR helper (yay/paru) found. Skipping AUR packages.")
                    all_failed.extend(filtered_aur)
                    aur_helper = None
            
            if aur_helper:
                success, failed = self.install_package_group(
                    filtered_aur,
                    "AUR",
                    [aur_helper, '-S', '--noconfirm']
                )
                all_successful.extend(success)
                all_failed.extend(failed)
        
        # Report results
        logger.info(f"\nInstallation Summary:")
        logger.info(f"  Successfully installed: {len(all_successful)} packages")
        logger.info(f"  Failed to install: {len(all_failed)} packages")
        
        if all_successful:
            logger.info("Successfully installed packages:")
            for pkg in all_successful:
                logger.info(f"  ✓ {pkg}")
        
        if all_failed:
            logger.error("Failed packages:")
            for pkg in all_failed:
                logger.error(f"  ✗ {pkg}")
        
        return len(all_failed) == 0

def main():
    parser = argparse.ArgumentParser(description='Install custom packages from system.yaml')
    parser.add_argument('--yaml', '-y', default='system.yaml',
                       help='Path to system.yaml file (default: system.yaml)')
    parser.add_argument('--dry-run', '-n', action='store_true',
                       help='Show what would be installed without actually installing')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        installer = PackageInstaller(args.yaml, args.dry_run)
        success = installer.install_packages()
        
        if success:
            logger.info("All packages installed successfully!")
            sys.exit(0)
        else:
            logger.error("Some packages failed to install. Check the log for details.")
            sys.exit(1)
            
    except Exception as e:
        logger.error(f"Script failed: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()