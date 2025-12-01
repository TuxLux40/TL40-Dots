#!/usr/bin/env bash

# NAS Mount Script via SSHFS
# Mounts NAS properly with correct user permissions

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
NAS_USER="Oliver"
NAS_HOST="os93-nas"
NAS_PATH="/home"
MOUNT_POINT="/mnt/nas"

# Get current user info
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo -e "${YELLOW}NAS Mount Configuration:${NC}"
echo "  Remote: ${NAS_USER}@${NAS_HOST}:${NAS_PATH}"
echo "  Mount point: ${MOUNT_POINT}"
echo "  Local user: ${CURRENT_USER} (uid=${CURRENT_UID}, gid=${CURRENT_GID})"
echo ""

# Ensure user_allow_other is enabled in fuse.conf
if ! grep -q "^user_allow_other" /etc/fuse.conf 2>/dev/null; then
    echo -e "${YELLOW}Enabling user_allow_other in /etc/fuse.conf...${NC}"
    echo 'user_allow_other' | sudo tee -a /etc/fuse.conf > /dev/null
    echo -e "${GREEN}✓ fuse.conf configured${NC}"
fi

# Check if already mounted
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo -e "${YELLOW}NAS is already mounted at $MOUNT_POINT${NC}"
    
    # Check if mounted with correct permissions
    MOUNT_INFO=$(mount | grep "$MOUNT_POINT")
    if echo "$MOUNT_INFO" | grep -q "user_id=$CURRENT_UID,group_id=$CURRENT_GID"; then
        echo -e "${GREEN}✓ Mounted with correct permissions${NC}"
        exit 0
    else
        echo -e "${RED}✗ Mounted with wrong permissions (probably as root)${NC}"
        echo -e "${YELLOW}Unmounting...${NC}"
        sudo umount "$MOUNT_POINT" || {
            echo -e "${RED}Failed to unmount. Try: fusermount -u $MOUNT_POINT${NC}"
            exit 1
        }
    fi
fi

# Create mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    echo -e "${YELLOW}Creating mount point...${NC}"
    sudo mkdir -p "$MOUNT_POINT"
fi

# Set correct ownership
sudo chown "$CURRENT_USER:$CURRENT_USER" "$MOUNT_POINT"

# Mount with correct user permissions
echo -e "${YELLOW}Mounting NAS...${NC}"
sshfs "${NAS_USER}@${NAS_HOST}:${NAS_PATH}" "$MOUNT_POINT" \
    -o uid="$CURRENT_UID" \
    -o gid="$CURRENT_GID" \
    -o allow_other \
    -o reconnect \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o compression=yes

# Verify mount
if mountpoint -q "$MOUNT_POINT"; then
    echo -e "${GREEN}✓ NAS mounted successfully at $MOUNT_POINT${NC}"
    echo ""
    echo "Mount info:"
    mount | grep "$MOUNT_POINT"
    echo ""
    echo "Contents:"
    ls -lah "$MOUNT_POINT" | head -10
else
    echo -e "${RED}✗ Failed to mount NAS${NC}"
    exit 1
fi
