#!/usr/bin/env bash
# sudo / PAM / YubiKey Diagnostic (read-only)
# Checks the status of sudo, PAM, PGP/GPG and YubiKey configurations
# Creates a log file in the user's home directory

set -Eeuo pipefail

# ---------- Pretty printing ----------
COLS="$(tput cols 2>/dev/null || echo 80)"
BOLD="$(tput bold 2>/dev/null || echo)"
DIM="$(tput dim 2>/dev/null || echo)"
RESET="$(tput sgr0 2>/dev/null || echo)"
RED="$(tput setaf 1 2>/dev/null || echo)"
GRN="$(tput setaf 2 2>/dev/null || echo)"
YLW="$(tput setaf 3 2>/dev/null || echo)"
BLU="$(tput setaf 4 2>/dev/null || echo)"
CYN="$(tput setaf 6 2>/dev/null || echo)"

hr(){ printf "%s\n" "$(printf '─%.0s' $(seq 1 "$COLS"))"; }
h1(){ printf "\n${BOLD}%s${RESET}\n" "◆ $*"; hr; }
h2(){ printf "\n${BLU}%s${RESET}\n" "→ $*"; }
ok(){ printf "${GRN}✔${RESET} %s\n" "$*"; }
warn(){ printf "${YLW}⚠${RESET} %s\n" "$*"; }
err(){ printf "${RED}✖${RESET} %s\n" "$*"; }
kv(){ printf "  %-28s %s\n" "$1:" "${2:-}"; }
code(){ printf "%s\n" "$*" | sed 's/^/    /'; }

# ---------- Logging ----------
TS="$(date +%Y%m%d_%H%M%S)"
LOG="${HOME}/sudo_diag_plus_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

# ---------- Safety / env ----------
# This script sets up a diagnostic environment for running commands with formatted output.
# It enables alias expansion, unaliases 'grep' to avoid interference, and sets locale to C for consistent behavior.
# It also clears GREP_OPTIONS to prevent unexpected grep modifications.
# 
# Functions:
# - cmd: Checks if a given command is available in the system's PATH.
#   Usage: cmd <command_name>
#   Returns: 0 if command exists, non-zero otherwise.
# 
# - run: Executes a command and formats its output with indentation and color (assuming DIM and RESET are defined elsewhere).
#   It prints the command being run, then pipes the output through sed for indentation.
#   Usage: run <command> [args...]
#   Note: This function uses eval, so be cautious with user input to avoid security risks.
shopt -s expand_aliases || true
unalias grep 2>/dev/null || true
export LC_ALL=C
export GREP_OPTIONS=

cmd(){ command -v "$1" >/dev/null 2>&1; }
run(){ printf "${DIM}$ %s${RESET}\n" "$*"; eval "$*" 2>&1 | sed 's/^/    /'; }

timeout_run(){ local t="$1"; shift; if cmd timeout; then run timeout "$t" "$@"; else run "$@"; fi; }

# ---------- Start ----------
# This section of the script outputs metadata about the system under a "Meta" header.
# It uses the h1 function to print the header and kv function to display key-value pairs.
# The information includes:
# - Current date and time in ISO format.
# - Hostname (using hostnamectl if available, otherwise hostname).
# - Kernel details (system, release, machine, and operating system).
# - Current user and their UID.
# - Shell environment variable.
# - Number of terminal columns.
# - Operating system name and version from /etc/os-release if readable.
h1 "Meta"
kv "Time" "$(date -Is)"
kv "Host" "$(hostnamectl --static 2>/dev/null || hostname)"
kv "Kernel" "$(uname -srmo)"
kv "User/UID" "$(whoami) / $(id -u)"
kv "Shell" "$SHELL"
kv "Terminal cols" "$COLS"
if [ -r /etc/os-release ]; then
    . /etc/os-release
    kv "OS" "${PRETTY_NAME:-$NAME $VERSION}"
fi

# This section of the script performs diagnostics on user groups and sudo configuration.
# It starts by displaying the current user's ID information using the 'id' command.
# If the 'getent' command is available, it retrieves and displays information about the 'wheel' and 'sudo' groups.
# Next, it tests sudo access without prompting for a password using 'sudo -n true', capturing and displaying the output or 'ok' if successful.
# Finally, it displays the first 120 lines of sudo's version information using 'sudo -V' piped through 'sed'.
h1 "Groups & sudo Basics"
run id
if cmd getent; then run 'getent group wheel sudo || true'; fi
run 'printf "sudo -n test → "; out=$(sudo -n true 2>&1 || true); echo "${out:-ok}"'
run 'sudo -V | sed -n "1,120p"'

# This section of the script diagnoses PAM (Pluggable Authentication Modules) configurations
# related to sudo authentication. It performs the following checks:
# - Displays the contents of /etc/pam.d/sudo (up to 200 lines) if readable, or warns if not found.
# - Shows /etc/pam.d/system-auth if available.
# - Lists PAM modules linked to the sudo binary.
# - Searches for U2F, YubiKey, or fingerprint PAM modules in /etc/pam.d.
# - Reports the current authselect configuration if available.
h1 "PAM Stacks"
h2 "/etc/pam.d/sudo"
[ -r /etc/pam.d/sudo ] && run 'sed -n "1,200p" /etc/pam.d/sudo' || warn "no sudo PAM file"
h2 "/etc/pam.d/system-auth (if available)"
run 'sed -n "1,200p" /etc/pam.d/system-auth 2>/dev/null || true'
h2 "PAM Modules in sudo Binary"
run 'ldd "$(command -v sudo)" | command grep -i pam || true'
h2 "Search for U2F/YubiKey PAM"
run 'grep -R -n "pam_u2f\|pam_yubico\|pam_fprintd" /etc/pam.d 2>/dev/null || echo "No u2f/yubico/fprintd in /etc/pam.d"'
h2 "authselect (if available)"
run 'authselect current 2>/dev/null || echo "authselect: not used"'

# This section diagnoses password and account security status for the current user.
# It checks for failed login attempts using faillock, displays the faillock configuration
# (either from /etc/security/faillock.conf or files in /etc/security/faillock.conf.d/),
# and retrieves password status and account aging information via passwd and chage commands.
# All commands are run with error suppression to avoid script failure on missing files or permissions.
h1 "faillock / Password & Account Status"
run 'faillock --user "$USER" || true'
if [ -r /etc/security/faillock.conf ]; then
    h2 "/etc/security/faillock.conf"
    run 'sed -n "1,200p" /etc/security/faillock.conf'
else
    h2 "/etc/security/faillock.conf.d/*.conf"
    run 'ls -l /etc/security/faillock.conf.d 2>/dev/null || true'
    run 'grep -R -n . /etc/security/faillock.conf.d 2>/dev/null || true'
fi
run 'passwd -S "$USER" || true'
run 'chage -l "$USER" || true'

# This section of the script performs diagnostics on sudoers configuration files.
# It starts by displaying a header for "Sudoers Rules" and then searches for specific Defaults entries
# in /etc/sudoers and /etc/sudoers.d that relate to authentication methods (authenticate, targetpw, rootpw, runaspw).
# If no matches are found, it outputs "No relevant Defaults".
# Next, it searches for any non-commented lines containing "rootpw" in the same files.
# Then, it displays a subheader for "sudoers Validation (visudo -c)" and checks if visudo command is available.
# If available, it runs visudo -c to validate the sudoers files and captures the output.
# If visudo is not available, it issues a warning.
h1 "Sudoers Rules"
run 'grep -R -nE "^[[:space:]]*Defaults[[:space:]]+(!?authenticate|targetpw|rootpw|runaspw)" /etc/sudoers /etc/sudoers.d 2>/dev/null || echo "No relevant Defaults"'
run 'grep -R -nE "^[^#].*rootpw" /etc/sudoers /etc/sudoers.d 2>/dev/null || true'
h2 "sudoers Validation (visudo -c)"
if cmd visudo; then run 'visudo -c 2>&1 | tail -n +1'; else warn "visudo not available"; fi

# This section of the script diagnoses the system's locale and keyboard settings.
# It starts by displaying a header for "Locale / Keyboard".
# Then, it runs the 'localectl status' command to check the current locale configuration,
# using '|| true' to prevent script failure if the command is not available.
# If the file /etc/vconsole.conf is readable, it displays a subheader and outputs its contents.
# Similarly, if /etc/default/keyboard is readable, it displays a subheader and outputs its contents.
# Finally, it uses the 'kv' function to display key-value pairs for environment variables:
# XKBMODEL (defaulting to empty if not set), XKBVARIANT (defaulting to empty), and XKBOPTIONS (defaulting to empty).
# This helps in troubleshooting keyboard and locale issues on the system.
h1 "Locale / Keyboard"
run 'localectl status || true'
[ -r /etc/vconsole.conf ] && { h2 "/etc/vconsole.conf"; run 'cat /etc/vconsole.conf'; }
[ -r /etc/default/keyboard ] && { h2 "/etc/default/keyboard"; run 'cat /etc/default/keyboard'; }
kv "XKBMODEL" "${XKBMODEL:-}"; kv "XKBVARIANT" "${XKBVARIANT:-}"; kv "XKBOPTIONS" "${XKBOPTIONS:-}"

# This section of the script diagnoses the systemd-homed service for the current user.
# It attempts to inspect the user's home directory using 'homectl inspect', piping the output through 'sed' to limit it to the first 150 lines.
# If the command fails (e.g., homed not in use), it falls back to echoing "homed: not used" to indicate the service is not utilized.
h1 "systemd-homed"
run 'homectl inspect "$USER" 2>/dev/null | sed -n "1,150p" || echo "homed: not used"'

# Diagnostic script for YubiKey/U2F setups
# 
# This section of the script focuses on diagnosing YubiKey and U2F (Universal 2nd Factor) configurations and libraries.
# It performs the following checks:
# 
# 1. **U2F Config Files**:
#    - Lists the ~/.config/Yubico directory and its contents if present.
#    - Displays the first 5 lines of ~/.config/Yubico/u2f_keys if the file exists.
#    - Checks for /etc/u2f_mappings file.
# 
# 2. **PAM Modules Availability**:
#    - Searches for pam_u2f.so and pam_yubico.so in common security library directories.
#    - Uses ldconfig to list loaded libraries related to PAM U2F or Yubico.
# 
# 3. **USB Devices**:
#    - If lsusb is available, lists USB devices and filters for YubiKey, Nitrokey, or Solo tokens.
#    - If udevadm is available, queries properties of /dev/hidraw0 for vendor and model IDs.
# 
# The script uses helper functions like h1, h2, run, cmd, and warn (assumed to be defined elsewhere) for formatting output and handling commands.
# It suppresses errors and provides fallbacks (e.g., "not present" or "empty") for missing files or unavailable commands.
h1 "YubiKey / U2F / Libraries"
h2 "U2F Config Files"
run 'ls -ld ~/.config/Yubico 2>/dev/null || true'
run 'ls -l ~/.config/Yubico/* 2>/dev/null || echo "~/.config/Yubico empty"'
run 'echo "# ~/.config/Yubico/u2f_keys"; [ -f ~/.config/Yubico/u2f_keys ] && sed -n "1,5p" ~/.config/Yubico/u2f_keys || echo "not present"'
run 'ls -l /etc/u2f_mappings 2>/dev/null || echo "/etc/u2f_mappings not present"'
h2 "pam_u2f / pam_yubico available?"
run 'for p in /lib/security /lib64/security /usr/lib/security /usr/lib64/security; do [ -d "$p" ] && ls "$p"/pam_u2f.so "$p"/pam_yubico.so 2>/dev/null; done || true'
run 'ldconfig -p 2>/dev/null | command grep -i "pam_\(u2f\|yubico\)" || true'
h2 "USB / Devices"
if cmd lsusb; then run 'lsusb | command grep -i "yubi\|nitro\|solo" || echo "no token found via lsusb or lsusb empty"'; else warn "lsusb not available"; fi
if cmd udevadm; then run 'udevadm info -q property -n /dev/hidraw0 2>/dev/null | command grep -E "ID_VENDOR|ID_MODEL" || true'; fi

# Diagnostic script for GnuPG, Smartcard, and Agent setup.
# This script performs a comprehensive check of the GnuPG environment, including:
# - Versions and directories of GnuPG components.
# - Configuration files in ~/.gnupg (gpg-agent.conf and scdaemon.conf).
# - Running processes related to gpg-agent, scdaemon, and pcscd.
# - Systemd user units and sockets for GPG and PCSCD.
# - Smartcard status via gpg --card-status.
# - Agent IPC interactions using gpg-connect-agent.
# - YubiKey Manager details if available (ykman command).
# - SSH Agent Bridge configuration and socket information.
# Commands are executed with timeouts to prevent hanging, and errors are handled gracefully.
# Requires functions like h1, h2, run, timeout_run, kv, warn, and cmd to be defined elsewhere.
h1 "GnuPG / Smartcard / Agent"
h2 "Versions & Dirs"
run 'gpg --version 2>/dev/null | sed -n "1,6p" || echo "gpg not available"'
run 'gpgconf --list-dirs 2>/dev/null || true'
h2 "Agent Configuration (~/.gnupg)"
run 'ls -l ~/.gnupg 2>/dev/null || true'
run 'sed -n "1,120p" ~/.gnupg/gpg-agent.conf 2>/dev/null || echo "no ~/.gnupg/gpg-agent.conf"'
run 'sed -n "1,120p" ~/.gnupg/scdaemon.conf 2>/dev/null || echo "no ~/.gnupg/scdaemon.conf"'
h2 "Running Processes (gpg-agent/scdaemon/pcscd)"
run 'ps -ef | command grep -iE "(gpg-agent|scdaemon|pcscd)" | command grep -v grep || echo "no processes found"'
h2 "systemd User Units"
run 'systemctl --user list-sockets 2>/dev/null | command grep -i gpg || echo "no gpg sockets visible"'
run 'systemctl --user list-units 2>/dev/null | command grep -iE "gpg|pcscd" || echo "no relevant user units"'
h2 "Smartcard Status"
timeout_run 7s gpg --card-status 2>/dev/null || true
h2 "Agent IPC"
timeout_run 5s gpg-connect-agent 'GETINFO version' /bye 2>/dev/null || true
timeout_run 5s gpg-connect-agent 'GETINFO pid' /bye 2>/dev/null || true
timeout_run 5s gpg-connect-agent 'SCD GETINFO reader_list' /bye 2>/dev/null || true
h2 "YubiKey Manager (if available)"
if cmd ykman; then
    timeout_run 7s ykman list || true
    timeout_run 7s ykman info || true
    timeout_run 7s ykman piv info || true
else
    warn "ykman not installed"
fi
h2 "SSH Agent Bridge"
kv "SSH_AUTH_SOCK" "${SSH_AUTH_SOCK:-}"
run 'gpgconf --list-options gpg-agent 2>/dev/null | command grep -E "enable-ssh-support|scdaemon-program" || true'

h1 "Logs (last 2h) – sudo/pam/auth/gpg/u2f"
if sudo -n true 2>/dev/null; then
    run 'sudo journalctl --since -2h 2>/dev/null | command grep -iE "sudo|pam|auth|faillock|u2f|yubi|gpg|scdaemon|pcscd" | tail -n 400 || true'
else
    warn "journalctl root log without sudo may be restricted"
    run 'journalctl --user --since -2h 2>/dev/null | command grep -iE "sudo|pam|auth|gpg|u2f|yubi|scdaemon|pcscd" | tail -n 200 || true'
    run 'journalctl --since -2h 2>/dev/null | tail -n 0 || true'
fi

# This script performs a live test of sudo functionality, which is optional and best-effort.
# It resets the sudo token to ensure a clean state for testing.
# Then, it attempts to run 'sudo -n true' without a password, expecting a "password is required" error.
# Finally, it lists sudo privileges using 'sudo -l', with a timeout to prevent hanging, and uses 'script' if available for better output capture.
h1 "Live Test (optional, best effort)"
h2 "sudo Token reset"
run 'sudo -K 2>/dev/null || true'
h2 "sudo -n (without password) Expected: „a password is required“"
run 'sudo -n true 2>&1 || true'
h2 "sudo -l (may ask for password; abort after 8s)"
if cmd script; then
    timeout_run 8s script -q -c "sudo -l" /dev/null || true
else
    timeout_run 8s sudo -l || true
fi

# Summary Section: Performs heuristic checks on the log file to assess security configurations.
# - Checks for PAM-U2F or YubiKey entries in the log; reports OK if found, warns if not.
# - Scans for authentication failures; warns if any are detected.
# - Verifies if pam_faillock is active; advises checking configuration if present.
# - Looks for smartcard detection via gpg; reports OK if serial number found, warns otherwise.
# - Prints a horizontal rule for separation.
# - Displays the path where the log file is saved.
h1 "Summary"
# Heuristic
if grep -qi "pam_u2f\|pam_yubico" "$LOG"; then
    ok "PAM-U2F/YubiKey entries found."
else
    warn "No PAM-U2F/YubiKey entries found."
fi
if grep -qi "Authentication failure" "$LOG"; then
    warn "Auth failures in logs."
fi
if grep -qi "pam_faillock" "$LOG"; then
    ok "faillock active; check configuration above."
fi
if grep -qi "Serial number" "$LOG"; then
    ok "Smartcard detected (gpg --card-status)."
else
    warn "Smartcard not confirmed via gpg."
fi

hr
echo "Log saved at: ${LOG}"

