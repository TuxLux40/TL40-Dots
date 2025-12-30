#! /bin/bash
# Setup script for virt-manager
sudo pacman -Syu qemu-full virt-manager libvirt dnsmasq bridge-utils virt-viewer ebtables openbsd-netcat --needed --noconfirm
sudo systemctl enable --now libvirtd
sudo systemctl enable --now virtlogd
sleep 2
# Add user to libvirt group (important for non-root access and polkit)
sudo usermod -aG libvirt $USER