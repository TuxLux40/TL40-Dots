#!/bin/bash
# Configuring Linux DNS for Tailscale
# Sourced from the official documentation: https://tailscale.com/kb/1188/linux-dns
# Must be run with root privileges.
# Tailscale attempts to interoperate with any Linux DNS configuration it finds already present. Unfortunately, some are not entirely amenable to cooperatively managing the host's DNS configuration.

# Common problems
# NetworkManager + systemd-resolved
# If you're using both NetworkManager and systemd-resolved (as in common in many distros), you'll want to make sure that /etc/resolv.conf is a symlink to /run/systemd/resolve/stub-resolv.conf. That should be the default. If not,
# When NetworkManager sees that symlink is present, its default behavior is to use systemd-resolved and not take over the resolv.conf file.

# Automatically elevate to root if not already running as root
if [ "$EUID" -ne 0 ]; then
  printf "Not running as root. Elevating privileges using sudo...\n"
  exec sudo bash "$0" "$@"
fi

printf "Symlinking /etc/resolv.conf to systemd-resolved stub resolver...\n"
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
printf "Done\n"
cat /etc/resolv.conf

# After fixing, restart everything:
printf "Restarting systemd-resolved, NetworkManager, and tailscaled services...\n"
systemctl restart systemd-resolved
systemctl restart NetworkManager
systemctl restart tailscaled
printf "Services restarted.\n"

# DHCP dhclient overwriting /etc/resolv.conf
# Without any DNS management system installed, DHCP clients like dhclient and programs like tailscaled have no other options than rewriting the /etc/resolv.conf file themselves, which results in them sometimes fighting with each other. (For instance, a DHCP renewal rewriting the resolv.conf resulting in loss of MagicDNS functionality.)
# Possible workarounds are to use resolvconf or systemd-resolved. Issue 2334 tracks making Tailscale react to other programs updating resolv.conf so Tailscale can add itself back.