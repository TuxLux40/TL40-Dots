#!/usr/bin/env bash

# Creates and enables a systemd unit for the NAS mount
UNIT_PATH="/etc/systemd/system/nas-mount.service"

sudo mkdir -p /mnt/nas

sudo tee "$UNIT_PATH" > /dev/null <<EOF
[Unit]
Description=Mount NAS via sshfs
After=network-online.target
Requires=network-online.target

[Service]
Type=simple
User=$(whoami)
ExecStart=/usr/bin/sshfs oliver@os93-nas:/home /mnt/nas/
ExecStop=/bin/fusermount -u /mnt/nas/
Restart=on-failure

[Install]
WantedBy=default.target
EOF
printf "Created systemd unit at %s\n" "$UNIT_PATH" "Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable nas-mount.service
sudo systemctl start nas-mount.service
printf "NAS mount service started and enabled.\n"