#!/bin/bash

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

# Create symlinks from NAS to local directories
## Photos
ln -s /run/user/1000/gvfs/sftp:host=$NAS_IP_ADDRESS,user=oliver/homes/Oliver/Photos ~/Pictures/
## Pics
ln -s /run/user/1000/gvfs/sftp:host=$NAS_IP_ADDRESS,user=oliver/homes/Oliver/04_Pics ~/Pictures/04_Pics
## Videos
ln -s /run/user/1000/gvfs/sftp:host=$NAS_IP_ADDRESS,user=oliver/homes/Oliver/03_Videos ~/Videos/03_Videos
## Music
ln -s /run/user/1000/gvfs/sftp:host=$NAS_IP_ADDRESS,user=oliver/homes/Oliver/Music ~/Music
## Documents
ln -s /run/user/1000/gvfs/sftp:host=$NAS_IP_ADDRESS,user=oliver/homes/Oliver/01_Documents ~/Documents/
## eBooks
ln -s /run/user/1000/gvfs/sftp:host=$NAS_IP_ADDRESS,user=oliver/homes/Oliver/09_eBooks ~/Documents/eBooks