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
import time

# Try to import rich for better output, fallback to standard logging if not available
try:
    from rich.console import Console
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeRemainingColumn
    from rich.table import Table
    from rich.panel import Panel
    from rich.text import Text
    from rich.logging import RichHandler
    from rich.live import Live
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

if RICH_AVAILABLE:
    console = Console()
    
    # Configure logging with Rich
    logging.basicConfig(
        level=logging.INFO,
        format="%(message)s",
        datefmt="[%X]",
        handlers=[
            logging.FileHandler('package_install.log'),
            RichHandler(console=console, show_path=False)
        ]
    )
else:
    # Fallback to standard logging
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
    def __init__(self, yaml_path: str, dry_run: bool = False, skip_aur: bool = False, 
                 skip_chaotic: bool = False, only_aur: bool = False, only_chaotic: bool = False):
        self.yaml_path = Path(yaml_path)
        self.dry_run = dry_run
        self.skip_aur = skip_aur
        self.skip_chaotic = skip_chaotic
        self.only_aur = only_aur
        self.only_chaotic = only_chaotic
        self.failed_packages = []
        self.installed_packages = []
        
        if not self.yaml_path.exists():
            raise FileNotFoundError(f"YAML file not found: {yaml_path}")
    
    def print_info(self, message: str):
        """Print info message with appropriate formatting."""
        if RICH_AVAILABLE:
            console.print(f"[blue]ℹ[/blue] {message}")
        else:
            logger.info(message)
    
    def print_success(self, message: str):
        """Print success message with appropriate formatting."""
        if RICH_AVAILABLE:
            console.print(f"[green]✓[/green] {message}")
        else:
            logger.info(f"✓ {message}")
    
    def print_warning(self, message: str):
        """Print warning message with appropriate formatting."""
        if RICH_AVAILABLE:
            console.print(f"[yellow]⚠[/yellow] {message}")
        else:
            logger.warning(message)
    
    def print_error(self, message: str):
        """Print error message with appropriate formatting."""
        if RICH_AVAILABLE:
            console.print(f"[red]✗[/red] {message}")
        else:
            logger.error(message)
    
    def create_summary_table(self, installed: List[str], failed: List[str]) -> Table:
        """Create a summary table for installation results."""
        if not RICH_AVAILABLE:
            return None
            
        table = Table(title="Installation Summary", show_header=True, header_style="bold magenta")
        table.add_column("Status", style="dim", width=8)
        table.add_column("Count", justify="center", style="dim", width=8)
        table.add_column("Packages", style="dim")
        
        if installed:
            table.add_row(
                "[green]Success[/green]", 
                str(len(installed)), 
                ", ".join(installed[:10]) + ("..." if len(installed) > 10 else "")
            )
        
        if failed:
            table.add_row(
                "[red]Failed[/red]", 
                str(len(failed)), 
                ", ".join(failed[:10]) + ("..." if len(failed) > 10 else "")
            )
        
        return table
    
    def load_yaml(self) -> Dict:
        """Load and parse the YAML file."""
        try:
            with open(self.yaml_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
            self.print_success(f"Loaded YAML from {self.yaml_path}")
            return data
        except Exception as e:
            self.print_error(f"Failed to load YAML file: {e}")
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
            self.print_info(f"No {package_type} packages to install")
            return [], []
        
        successful = []
        failed = []
        
        if RICH_AVAILABLE:
            # Use Rich progress bar for better visual feedback
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                BarColumn(),
                TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
                TextColumn("({task.completed}/{task.total})"),
                TimeRemainingColumn(),
                console=console
            ) as progress:
                task = progress.add_task(f"Installing {package_type} packages...", total=len(packages))
                
                for i, package in enumerate(packages):
                    progress.update(task, description=f"Installing {package_type}: {package}")
                    
                    if self.dry_run:
                        self.print_info(f"[DRY RUN] Would install {package_type} package: {package}")
                        successful.append(package)
                        time.sleep(0.1)  # Small delay for visual effect in dry-run
                    else:
                        success = self._install_single_package(package, package_type, install_command)
                        if success:
                            successful.append(package)
                        else:
                            failed.append(package)
                    
                    progress.update(task, advance=1)
        else:
            # Fallback without Rich
            self.print_info(f"Installing {len(packages)} {package_type} packages...")
            for package in packages:
                if self.dry_run:
                    self.print_info(f"[DRY RUN] Would install {package_type} package: {package}")
                    successful.append(package)
                else:
                    success = self._install_single_package(package, package_type, install_command)
                    if success:
                        successful.append(package)
                    else:
                        failed.append(package)
        
        return successful, failed
    
    def _install_single_package(self, package: str, package_type: str, install_command: List[str]) -> bool:
        """Install a single package and return success status."""
        try:
            cmd = install_command + [package]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout per package
            )
            
            if result.returncode == 0:
                return True
            else:
                self.print_error(f"Failed to install {package}: {result.stderr.strip()}")
                logger.error(f"Command failed: {' '.join(cmd)}")
                logger.error(f"Stderr: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            self.print_error(f"Timeout installing {package}")
            return False
        except Exception as e:
            self.print_error(f"Error installing {package}: {e}")
            return False
    
    def setup_chaotic_repo(self) -> bool:
        """Ensure Chaotic-AUR repository is set up."""
        if self.dry_run:
            self.print_info("[DRY RUN] Would setup Chaotic-AUR repository")
            return True
        
        try:
            # Check if chaotic keyring is installed
            result = subprocess.run(['pacman', '-Qi', 'chaotic-keyring'], 
                                  capture_output=True, text=True)
            
            if result.returncode != 0:
                self.print_info("Installing Chaotic-AUR keyring...")
                subprocess.run(['sudo', 'pacman', '-Sy', '--noconfirm', 'chaotic-keyring'], 
                             check=True)
                
            # Check if chaotic mirrorlist is installed
            result = subprocess.run(['pacman', '-Qi', 'chaotic-mirrorlist'], 
                                  capture_output=True, text=True)
                                  
            if result.returncode != 0:
                self.print_info("Installing Chaotic-AUR mirrorlist...")
                subprocess.run(['sudo', 'pacman', '-Sy', '--noconfirm', 'chaotic-mirrorlist'], 
                             check=True)
            
            self.print_success("Chaotic-AUR repository setup complete")
            return True
            
        except Exception as e:
            self.print_error(f"Failed to setup Chaotic-AUR repository: {e}")
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
        
        # Apply installation filters
        if self.only_aur:
            filtered_regular = []
            filtered_chaotic = []
        elif self.only_chaotic:
            filtered_regular = []
            filtered_aur = []
        else:
            if self.skip_aur:
                filtered_aur = []
            if self.skip_chaotic:
                filtered_chaotic = []
        
        # Display package summary
        if RICH_AVAILABLE:
            summary_panel = Panel.fit(
                f"[bold]Package Installation Summary[/bold]\n\n"
                f"[blue]Regular packages:[/blue] {len(filtered_regular)}\n"
                f"[yellow]Chaotic packages:[/yellow] {len(filtered_chaotic)}\n"
                f"[green]AUR packages:[/green] {len(filtered_aur)}\n"
                f"[dim]Total packages:[/dim] {len(filtered_regular) + len(filtered_chaotic) + len(filtered_aur)}",
                title="📦 Installation Plan",
                border_style="blue"
            )
            console.print(summary_panel)
        else:
            self.print_info(f"Package summary:")
            self.print_info(f"  Regular packages: {len(filtered_regular)}")
            self.print_info(f"  Chaotic packages: {len(filtered_chaotic)}")
            self.print_info(f"  AUR packages: {len(filtered_aur)}")
        
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
                self.print_error("Skipping Chaotic packages due to repository setup failure")
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
                    self.print_error("No AUR helper (yay/paru) found. Skipping AUR packages.")
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
        
        # Display final results
        if RICH_AVAILABLE:
            console.print()
            table = self.create_summary_table(all_successful, all_failed)
            if table:
                console.print(table)
        else:
            # Fallback text output
            self.print_info(f"\nInstallation Summary:")
            self.print_info(f"  Successfully installed: {len(all_successful)} packages")
            self.print_info(f"  Failed to install: {len(all_failed)} packages")
        
        if all_successful:
            if not RICH_AVAILABLE:
                self.print_success("Successfully installed packages:")
                for pkg in all_successful[:10]:  # Show first 10
                    self.print_success(f"  {pkg}")
                if len(all_successful) > 10:
                    self.print_info(f"  ... and {len(all_successful) - 10} more")
        
        if all_failed:
            if not RICH_AVAILABLE:
                self.print_error("Failed packages:")
                for pkg in all_failed:
                    self.print_error(f"  {pkg}")
        
        return len(all_failed) == 0

def main():
    parser = argparse.ArgumentParser(description='Install custom packages from system.yaml')
    parser.add_argument('--yaml', '-y', default='system.yaml',
                       help='Path to system.yaml file (default: system.yaml)')
    parser.add_argument('--dry-run', '-n', action='store_true',
                       help='Show what would be installed without actually installing')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose logging')
    parser.add_argument('--skip-aur', action='store_true',
                       help='Skip AUR packages installation')
    parser.add_argument('--skip-chaotic', action='store_true',
                       help='Skip Chaotic-AUR packages installation')
    parser.add_argument('--only-aur', action='store_true',
                       help='Install only AUR packages')
    parser.add_argument('--only-chaotic', action='store_true',
                       help='Install only Chaotic-AUR packages')
    
    args = parser.parse_args()
    
    # Validate mutually exclusive options
    exclusive_options = [args.only_aur, args.only_chaotic, args.skip_aur and args.skip_chaotic]
    if sum(exclusive_options) > 1:
        print("Error: --only-aur, --only-chaotic, and --skip-aur with --skip-chaotic are mutually exclusive")
        sys.exit(1)
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        # Display header
        if RICH_AVAILABLE:
            header = Panel.fit(
                "[bold blue]TL40-BOS Custom Package Installer[/bold blue]\n"
                "[dim]Installing custom packages while excluding core system packages[/dim]",
                title="🚀 Package Installer",
                border_style="blue"
            )
            console.print(header)
        else:
            print("=== TL40-BOS Custom Package Installer ===")
            print("Installing custom packages while excluding core system packages")
        
        installer = PackageInstaller(
            args.yaml, 
            args.dry_run, 
            args.skip_aur, 
            args.skip_chaotic, 
            args.only_aur, 
            args.only_chaotic
        )
        success = installer.install_packages()
        
        if success:
            if RICH_AVAILABLE:
                console.print(Panel("🎉 All packages installed successfully!", 
                                   title="Success", border_style="green"))
            else:
                logger.info("All packages installed successfully!")
            sys.exit(0)
        else:
            if RICH_AVAILABLE:
                console.print(Panel("❌ Some packages failed to install. Check the log for details.", 
                                   title="Partial Success", border_style="yellow"))
            else:
                logger.error("Some packages failed to install. Check the log for details.")
            sys.exit(1)
            
    except Exception as e:
        if RICH_AVAILABLE:
            console.print(Panel(f"💥 Script failed: {e}", title="Error", border_style="red"))
        else:
            logger.error(f"Script failed: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()