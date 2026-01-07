#!/bin/bash
# QEMU and Virtual Machine Manager setup script for Arch Linux
# Sourced from https://wiki.cachyos.org/virtualization/qemu_and_vmm_setup/

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