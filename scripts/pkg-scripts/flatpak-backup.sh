#! /usr/bin/env bash
# Source: https://www.ctrl.blog/entry/backup-flatpak.html
# The following example script exports a list of your repositories as a list of commands that you can execute to reinstall your Flatpak repositories. You can pipe send the output list to a file as part of your backup script.

flatpak remotes --show-details | awk '{print "echo \"echo \\\x22$(base64 --wrap=0 < $HOME/.local/share/flatpak/repo/" $1 ".trustedkeys.gpg)\\\x22 | base64 -d | flatpak remote-add --if-not-exists --gpg-import=- --prio=\\\x22"$4"\\\x22 --title=\\\x22"$2"\\\x22 --user \\\x22"$1"\\\x22 \\\x22"$3"\\\x22\""}' | sh

# Get list of installed Flatpaks
flatpak list --app --show-details | \
awk '{print "flatpak install --assumeyes --user \""$2"\" \""$1}' | \
cut -d "/" -f1 | awk '{print $0"\""}'