# Fish configuration file

# ── PATH ─────────────────────────────────────────────────────────────────────
fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin
fish_add_path ~/.local/npm/bin
fish_add_path ~/.grok/bin

# ── Homebrew ─────────────────────────────────────────────────────────────────
set -l __brew /home/linuxbrew/.linuxbrew/bin/brew
if test -x $__brew
    command $__brew shellenv | source
end

# ── Environment ───────────────────────────────────────────────────────────────
set -gx EDITOR micro
set -gx VISUAL micro
set -gx TERM xterm-256color

# ── Shell settings ────────────────────────────────────────────────────────────
set -U fish_bell off
set -U fish_history_max_count 10000

# ── Man page colors ───────────────────────────────────────────────────────────
set -gx LESS_TERMCAP_mb '\e[01;31m'
set -gx LESS_TERMCAP_md '\e[01;31m'
set -gx LESS_TERMCAP_me '\e[0m'
set -gx LESS_TERMCAP_se '\e[0m'
set -gx LESS_TERMCAP_so '\e[01;44;33m'
set -gx LESS_TERMCAP_ue '\e[0m'
set -gx LESS_TERMCAP_us '\e[01;32m'

# ── Interactive session ───────────────────────────────────────────────────────
if status is-interactive
    # Greeting
    if type -q fastfetch
        fastfetch
    end

    # Shell integrations
    if type -q starship
        starship init fish | source
    end
    if type -q zoxide
        zoxide init fish | source
    end
    if type -q atuin
        atuin init fish | source
    end
    if type -q direnv
        direnv hook fish | source
    end

    # GPG agent needs the current TTY
    set -gx GPG_TTY (tty)

    # Qt platform theme (non-KDE sessions only)
    if test "$XDG_CURRENT_DESKTOP" != "KDE"
        set -gx QT_QPA_PLATFORMTHEME qt6ct
    end
end

# ── Aliases: editor ───────────────────────────────────────────────────────────
alias vim 'micro'
alias nano 'micro'
alias efish 'micro ~/.config/fish/config.fish'

# ── Aliases: navigation ───────────────────────────────────────────────────────
alias home 'cd ~'
alias cd.. 'cd ..'
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias web 'cd /var/www/html'
alias config 'cd ~/.config'
alias dl 'cd ~/Downloads'
alias docs 'cd ~/Documents'
alias pics 'cd ~/Pictures'
alias vids 'cd ~/Videos'
alias music 'cd ~/Music'
alias desk 'cd ~/Desktop'

# ── Aliases: file operations ──────────────────────────────────────────────────
alias cp 'cp -i'
alias mv 'mv -i'
alias rm 'trash -v'
alias mkdir 'mkdir -p'

# ── Aliases: listing (eza) ────────────────────────────────────────────────────
alias ls   'eza --all --group-directories-first --color=auto'
alias la   'eza -la --group-directories-first'
alias ll   'eza -l --group-directories-first'
alias lla  'eza -la'
alias las  'eza -a'
alias lls  'eza -l'
alias lx   'eza -l --sort=extension'
alias lk   'eza -l --sort=size'
alias lc   'eza -l --sort=changed'
alias lu   'eza -l --sort=accessed'
alias lr   'eza -lR'
alias lt   'eza -l --sort=modified'
alias lw   'eza -a --across'
alias labc 'eza -la --sort=name'

# ── Aliases: permissions ──────────────────────────────────────────────────────
alias mx  'chmod a+x'
alias 000 'chmod -R 000'
alias 644 'chmod -R 644'
alias 666 'chmod -R 666'
alias 755 'chmod -R 755'
alias 777 'chmod -R 777'

# ── Aliases: system ───────────────────────────────────────────────────────────
alias ps         'ps auxf'
alias ping       'ping -c 10'
alias less       'less -R'
alias grep       'ugrep --color=always -T'
alias openports  'netstat -nape --inet'
alias rebootsafe 'sudo shutdown -r now'
alias rebootforce 'sudo shutdown -r -n now'
alias da         'date "+%Y-%m-%d %A %T %Z"'
alias multitail  'multitail --no-repeat -c'

# ── Aliases: disk / filesystem ────────────────────────────────────────────────
alias folders    'du -h --max-depth=1'
alias tree       'eza -T --group-directories-first'
alias treed      'eza -TD --group-directories-first'
alias mountedinfo 'df -hT'

# ── Aliases: archives ────────────────────────────────────────────────────────
alias mktar 'tar -cvf'
alias mkbz2 'tar -cvjf'
alias mkgz  'tar -cvzf'
alias untar 'tar -xvf'
alias unbz2 'tar -xvjf'
alias ungz  'tar -xvzf'

# ── Aliases: TUI tools ────────────────────────────────────────────────────────
alias sysctl 'systemctl-tui'
alias stui   'systemctl-tui'
alias blui   'bluetui'
alias log    'lazyjournal'
alias sysctl 'systemctl-tui'
# ── Aliases: misc ─────────────────────────────────────────────────────────────
alias a 'aichat'

# ── Functions ─────────────────────────────────────────────────────────────────
function cd
    builtin cd $argv
    eza --all --group-directories-first --color=auto
end

function rmd
    command /bin/rm --recursive --force --verbose $argv
end

function lm
    eza -la --group-directories-first | command more
end

function lf
    eza -la --only-files
end

function ldir
    eza -la --only-dirs
end

function h
    history | ugrep
end

function p
    command ps aux | ugrep
end

function topcpu
    /bin/ps -eo pcpu,pid,user,args | command sort -k 1 -r | command head -10
end

function f
    command find . | ugrep
end

function diskspace
    command du -S | command sort -n -r | command more
end

function folderssort
    command find . -maxdepth 1 -type d -print0 | command xargs -0 du -sk | command sort -rn
end

function podman-clean
    podman container prune -f
    podman image prune -f
    podman network prune -f
    podman volume prune -f
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/oliver/.lmstudio/bin
# End of LM Studio CLI section

