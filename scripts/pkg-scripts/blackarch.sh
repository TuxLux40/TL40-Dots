#!/usr/bin/env bash
# BlackArch Linux repository setup script for Arch Linux and derivatives
# This script sets up BlackArch, fixes mirrors, and lets you interactively select categories to install.

set -e

echo -e "\n[BlackArch] Downloading and verifying setup script..."
curl -O https://blackarch.org/strap.sh
echo e26445d34490cc06bd14b51f9924debf569e0ecb strap.sh | sha1sum -c
chmod +x strap.sh
sudo ./strap.sh

# Fix BlackArch mirrors (replace with latest mirror list)
echo -e "\n[BlackArch] Updating mirror list..."
sudo curl -o /etc/pacman.d/blackarch-mirrorlist https://blackarch.org/blackarch-mirrorlist

sudo pacman -Syu

# Dry-run option
DRY_RUN=0
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=1
    shift
fi

# Get category descriptions from BlackArch website
declare -A descriptions
while read -r line; do
    cat=$(echo "$line" | cut -d'|' -f1 | xargs)
    desc=$(echo "$line" | cut -d'|' -f2- | xargs)
    descriptions[$cat]="$desc"
done < <(curl -s https://blackarch.org/tools.html | grep -oP '<tr><td><a href="[^"]+">blackarch-[^<]+</a></td><td>[^<]+</td>' | sed -E 's@<tr><td><a href="[^"]+">([^<]+)</a></td><td>([^<]+)</td>@\\1|\\2@')

echo -e "\nAvailable BlackArch categories:\n"
categories=( $(pacman -Sg | grep blackarch- | cut -d' ' -f1 | sort | uniq) )
for i in "${!categories[@]}"; do
    cat="${categories[$i]}"
    desc="${descriptions[$cat]}"
    printf "%2d) %s\n    %s\n" $((i+1)) "$cat" "${desc:-No description available.}"
done

echo -e "\nEnter the numbers of the categories you want to install (e.g. 1 5 12), or 'all' for everything:"
read -r input

if [[ "$input" == "all" ]]; then
    selected=("${categories[@]}")
else
    selected=()
    for num in $input; do
        idx=$((num-1))
        if [[ $idx -ge 0 && $idx -lt ${#categories[@]} ]]; then
            selected+=("${categories[$idx]}")
        fi
    done
fi

if [[ ${#selected[@]} -eq 0 ]]; then
    echo "No valid categories selected. Exiting."
    exit 1
fi

echo -e "\nThe following categories would be installed: ${selected[*]}\n"
if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY RUN] Installation not performed."
else
    sudo pacman -S --needed --overwrite='*' --noconfirm "${selected[@]}" || true
    echo -e "\nInstallation finished."
fi