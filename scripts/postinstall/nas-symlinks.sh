#!/bin/bash
# Command to mount NAS via SFTP: sshfs user@nas:/remote/path /mnt/nas
# Load environment variables
#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#source "$SCRIPT_DIR/.env"

# Create symlinks from NAS to local directories
## Photos
ln -s /mnt/nas/Photos ~/Pictures/ --force
## Pics
ln -s /mnt/nas/04_Pics ~/Pictures/ --force
## Videos
ln -s /mnt/nas/03_Videos ~/Videos/ --force
## Documents
ln -s /mnt/nas/01_Documents/ ~/Documents/ --force
ln -s /mnt/nas/99_Unsorted ~/Documents/ --force
## eBooks
ln -s /mnt/nas/09_eBooks ~/ --force
# IT Stuff
mkdir -p ~/IT
ln -s /mnt/nas/06_IT ~/ --force
# Gaming
ln -s /mnt/nas/13_Gaming ~/ --force