# YubiKey + sudo without typing a password (pam_u2f)

This guide explains how to use a YubiKey to approve `sudo` without typing a password. It corresponds to `scripts/yk-pam.sh` and includes verification and rollback steps.

Table of Contents

1. Summary
2. Prerequisites
3. One-command setup
4. Script changes
5. Manual enrollment
6. Testing
7. Adding a backup key
8. Recovery and rollback
9. Troubleshooting
10. FAQ

---

1. Summary

- Touch your YubiKey to approve `sudo` instead of typing your password.
- If your key isn’t present or fails, you can still fall back to your normal password.
- Your key identity is stored in a small file in your home folder: `~/.config/Yubico/u2f_keys`.

This is implemented using the Linux PAM module `pam_u2f` with the setting `auth sufficient pam_u2f.so cue` in `/etc/pam.d/sudo`.

- “sufficient” means: If YubiKey works, you’re in. If not, your password still works.
- “cue” makes `sudo` show a friendly prompt to touch the key.

---

---

2. Prerequisites

- A YubiKey that supports U2F/FIDO2 (almost all recent YubiKeys do).
- The `pam_u2f` software installed. Package names by distro:
  - Arch/Manjaro: `pam-u2f`
  - Debian/Ubuntu: `libpam-u2f`
  - Fedora/RHEL/CentOS/Rocky: `pam-u2f`
- Your user account must be able to use `sudo`.

Optional but helpful:

- YubiKey Manager (GUI/CLI) to check device configuration.

---

---

3. One-command setup (recommended)

Run the repo’s script. It will back up your current settings, add the PAM line, and enroll your YubiKey.

```fish
# Run the setup script
fish ~/Projects/TL40-Dots/scripts/yk-pam.sh
```

What you’ll see during enrollment:

- The LED on the YubiKey will blink.
- Touch the key when asked.
- The mapping file is written to `~/.config/Yubico/u2f_keys`.

You can optionally add a second backup YubiKey if you have one (the script will try once and skip silently if none is present).

---

---

4. What the script changes (exactly)

- Creates a backup at `~/pam_u2f_backup.tgz` containing:
  - `/etc/pam.d/sudo` (PAM sudo config)
  - `/etc/u2f_mappings` (if present)
- Appends this line to `/etc/pam.d/sudo`:

  `auth       sufficient   pam_u2f.so cue`

- Creates your per-user mapping file (owned by you):

  `~/.config/Yubico/u2f_keys`

- Sets secure permissions (`700` for the directory and `600` for the file).
- Optionally appends a second line for a backup YubiKey.

---

---

5. Manual enrollment (optional)

If you prefer to enroll manually or you’re on another machine without this repo, do:

```fish
# 1) Ensure the package is installed
# Arch/Manjaro:  pam-u2f
# Debian/Ubuntu: libpam-u2f
# Fedora/RHEL:   pam-u2f

# 2) Create the config directory with safe permissions
mkdir -p ~/.config/Yubico
chmod 700 ~/.config/Yubico

# 3) Enroll your primary key (touch the key when it blinks)
pamu2fcfg | tee ~/.config/Yubico/u2f_keys >/dev/null
chmod 600 ~/.config/Yubico/u2f_keys

# 4) (Optional) Enroll a second/backup key (touch that key now)
pamu2fcfg -n | tee -a ~/.config/Yubico/u2f_keys >/dev/null
```

Add the PAM rule for sudo:

```fish
# Append pam_u2f to sudo PAM. You will be asked for your password.
echo 'auth       sufficient   pam_u2f.so cue' | sudo tee -a /etc/pam.d/sudo >/dev/null
```

If you ran the above with `sudo` and want to create the mapping file for your login user instead of root, use:

```fish
set -l u $SUDO_USER
set -l h (eval echo ~$u)
mkdir -p $h/.config/Yubico
chmod 700 $h/.config/Yubico
sudo -u $u pamu2fcfg | sudo -u $u tee $h/.config/Yubico/u2f_keys >/dev/null
sudo -u $u pamu2fcfg -n | sudo -u $u tee -a $h/.config/Yubico/u2f_keys >/dev/null
chmod 600 $h/.config/Yubico/u2f_keys
```

---

---

6. How to test safely

```fish
# Forget cached sudo credentials (forces a fresh auth next time)
sudo -K

# Ask sudo to validate again
sudo -v
```

- You should see a prompt telling you to touch the YubiKey. Touch it.
- If you don’t touch or the key isn’t present, sudo should fall back to your password.

You can also run the included check script:

```fish
fish ~/Projects/TL40-Dots/scripts/sudo_diag.sh
```

---

---

7. Add a second (backup) YubiKey later

You can safely append another line for a second key any time:

```fish
pamu2fcfg -n | tee -a ~/.config/Yubico/u2f_keys >/dev/null
```

If you’re doing this while running `sudo`, see the “Manual enrollment” section for writing to the correct user’s home.

---

---

8. Recovery and rollback

If something goes wrong or you don’t like the change:

- Remove the last line you added to `/etc/pam.d/sudo`:

```fish
# Remove last line (the pam_u2f line) from the sudo PAM file
sudo sed -i '$ d' /etc/pam.d/sudo
```

- Restore the backup archive created by the script (if needed):

```fish
# Inspect what’s inside the backup
tar -tzf ~/pam_u2f_backup.tgz

# Restore (be careful: overrides current files)
sudo tar -C / -xzf ~/pam_u2f_backup.tgz
```

- You can also disable the feature just by temporarily moving your mapping file:

```fish
mv ~/.config/Yubico/u2f_keys ~/.config/Yubico/u2f_keys.disabled
```

---

---

9. Troubleshooting (common issues)

- “pamu2fcfg: command not found”

  - Install the right package: Arch `pam-u2f`, Debian/Ubuntu `libpam-u2f`, Fedora/RHEL `pam-u2f`.

- LED never blinks / no touch prompt

  - Reinsert the YubiKey and try again.
  - Ensure `pam_u2f` is actually listed in `/etc/pam.d/sudo`.
  - Some desktop environments or remote sessions can swallow prompts; try from a plain terminal.

- Sudo still asks for a password only, never for touch

  - Confirm this line exists (exactly) in `/etc/pam.d/sudo`:
    - `auth       sufficient   pam_u2f.so cue`
  - And confirm your `~/.config/Yubico/u2f_keys` file exists and is readable by your user.

- “Permission denied” writing `u2f_keys`

  - Make sure the directory exists and has the right permissions:
    - `mkdir -p ~/.config/Yubico && chmod 700 ~/.config/Yubico`
  - When running commands under `sudo`, write the file as your real user (see the manual section using `sudo -u` + `tee`).

- I get locked out of `sudo`
  - With `sufficient`, you should still be able to use your password if the key isn’t present.
  - If you must, remove the `pam_u2f` line from `/etc/pam.d/sudo` (see rollback above).

---

---

10. FAQ

- Per-user vs system-wide mapping?

  - This guide and the script use a per-user mapping at `~/.config/Yubico/u2f_keys`.
  - System-wide is also possible with `authfile=/etc/security/u2f_keys` in the PAM line, but then you must manage that file for all users. Per-user is simpler.

- Is the `u2f_keys` file sensitive?

  - It doesn’t contain your private key, but it does identify which security keys are allowed. Keep it owned by you with `600` permissions to avoid tampering.

- Does this work for `su`, login manager, SSH, etc.?

  - This guide only changes `sudo`. Other services can also use `pam_u2f`, but they need their own PAM config lines.

- U2F vs FIDO2 vs “passkeys”?
  - `pam_u2f` uses the older U2F (still very secure). Many YubiKeys support both U2F and FIDO2. For `sudo`, U2F is common and reliable.

---

## Uninstall / revert completely

1. Remove the `pam_u2f` line from `/etc/pam.d/sudo`:

```fish
sudo sed -i '/pam_u2f\.so/d' /etc/pam.d/sudo
```

2. Optionally delete your mapping file:

```fish
rm -f ~/.config/Yubico/u2f_keys
rmdir ~/.config/Yubico ^/dev/null; and true
```

3. Optionally remove the package:

```fish
# Arch/Manjaro
sudo pacman -R pam-u2f

# Debian/Ubuntu
sudo apt remove libpam-u2f

# Fedora/RHEL
sudo dnf remove pam-u2f
```

---

## Quick checklist

- [ ] Package installed (`pam-u2f` / `libpam-u2f`)
- [ ] PAM line present in `/etc/pam.d/sudo`
- [ ] `~/.config/Yubico/u2f_keys` exists and has the right permissions
- [ ] Touch prompt appears when running `sudo -v`

You’re done. Touch to approve, password as fallback.
