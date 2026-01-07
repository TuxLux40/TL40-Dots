#!/bin/bash
set -e
# Install packages
sudo pacman -S qemu-full virt-manager swtpm --needed --noconfirm
# Add user to libvirt group
sudo usermod -aG libvirt "$USER"
# Enable and start libvirtd service and socket
systemctl enable --now libvirtd.service
systemctl enable --now libvirtd.socket
# Enable default virtual network
sudo virsh net-autostart default