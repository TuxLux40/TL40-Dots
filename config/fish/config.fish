# Fish configuration file

if status is-interactive
	# Commands to run in interactive sessions can go here

	# Initialize tools and environment variables
	if type -q fastfetch
		fastfetch
	end

	# Initialize Starship prompt if installed
	if type -q starship
		starship init fish | source
	end

	# Initialize Zoxide if available
	if type -q zoxide
		zoxide init fish | source
	end

	# Initialize Atuin if available
	if type -q atuin
		atuin init fish | source
	end

	# Set GPG_TTY for gpg-agent
	if type -q tty
		set -gx GPG_TTY (tty)
	end
end

# Load Homebrew environment if available
set -l __brew_path /home/linuxbrew/.linuxbrew/bin/brew
if test -x $__brew_path
	command $__brew_path shellenv | source
end

# Set the default editor
set -gx EDITOR micro
set -gx VISUAL micro
function vim
    micro $argv
end
function nano
    micro $argv
end

# Automatically list directory contents on cd
function cd
    builtin cd $argv
    ls
end

# Disable the bell (Fish equivalent)
set -U fish_bell off

# Expand the history size (Fish equivalent)
set -U fish_history_max_count 10000

# Enable colorized output for ls-compatible tools
set -gx CLICOLOR 1
set -gx LS_COLORS 'no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# GREP_OPTIONS is deprecated; rely on aliases or GREP_COLORS instead
set -e GREP_OPTIONS

# Check if ugrep is installed
if command -v ugrep >/dev/null 2>&1
    function grep
        ugrep --color=always -T $argv
    end
else if command -v rg >/dev/null 2>&1
    function grep
        rg $argv
    end
else
    function grep
        /usr/bin/grep $argv
    end
end
# unset GREP_OPTIONS  # Bash-specific, already handled

# Color for manpages in less makes manpages a little easier to read
set -gx LESS_TERMCAP_mb '\e[01;31m'
set -gx LESS_TERMCAP_md '\e[01;31m'
set -gx LESS_TERMCAP_me '\e[0m'
set -gx LESS_TERMCAP_se '\e[0m'
set -gx LESS_TERMCAP_so '\e[01;44;33m'
set -gx LESS_TERMCAP_ue '\e[0m'
set -gx LESS_TERMCAP_us '\e[01;32m'

############################################
#                 FUNCTIONS               #
############################################
# Functions to change the directory
function web
    cd /var/www/html
end
function config
    cd ~/.config
end
function dl
    cd ~/Downloads
end
function docs
    cd ~/Documents
end
function pics
    cd ~/Pictures
end
function vids
    cd ~/Videos
end
function music
    cd ~/Music
end
function desk
    cd ~/Desktop
end
function projects
    cd ~/Projects
end
# Edit this fish config file
function efish
    micro ~/.config/fish/config.fish $argv
end
# function to show the date
function da
    date "+%Y-%m-%d %A %T %Z"
end
# Miscellaneous functions
function cp
    command cp -i $argv
end
function mv
    command mv -i $argv
end
function rm
    if command -v trash >/dev/null 2>&1
        trash -v $argv
    else
        command rm $argv
    end
end
function mkdir
    command mkdir -p $argv
end
function ps
    command ps auxf $argv
end
function ping
    command ping -c 10 $argv
end
function less
    command less -R $argv
end
function multitail
    if command -v multitail >/dev/null 2>&1
        multitail --no-repeat -c $argv
    else
        echo "multitail not installed"
    end
end
function a
    if command -v aichat >/dev/null 2>&1
        aichat $argv
    else
        echo "aichat not installed"
    end
end
# Alias's for TUI tools
function sysctl
    if command -v systemctl-tui >/dev/null 2>&1
        systemctl-tui $argv
    else
        echo "systemctl-tui not installed"
    end
end
function stui
    if command -v systemctl-tui >/dev/null 2>&1
        systemctl-tui $argv
    else
        echo "systemctl-tui not installed"
    end
end
function blui
    if command -v bluetui >/dev/null 2>&1
        bluetui $argv
    else
        echo "bluetui not installed"
    end
end
# Change directory functions
function home
    cd ~
end
function cd..
    cd ..
end
function ..
    cd ..
end
function ...
    cd ../..
end
function ....
    cd ../../..
end
function .....
    cd ../../../..
end
# Remove a directory and all files
function rmd
    /bin/rm --recursive --force --verbose $argv
end
# Functions for multiple directory listing commands
function la
    ls -Alh $argv
end
function ls
    command ls -aFh --color=always $argv
end
function lx
    ls -lXBh $argv
end
function lk
    ls -lSrh $argv
end
function lc
    ls -ltcrh $argv
end
function lu
    ls -lturh $argv
end
function lr
    ls -lRh $argv
end
function lt
    ls -ltrh $argv
end
function lm
    ls -alh | more $argv
end
function lw
    ls -xAh $argv
end
function ll
    ls -Fls $argv
end
function labc
    ls -lap $argv
end
function lf
    ls -l | egrep -v '^d' $argv
end
function ldir
    ls -l | egrep '^d' $argv
end
function lla
    ls -Al $argv
end
function las
    ls -A $argv
end
function lls
    ls -l $argv
end
# chmod functions
function mx
    chmod a+x $argv
end
function 000
    chmod -R 000 $argv
end
function 644
    chmod -R 644 $argv
end
function 666
    chmod -R 666 $argv
end
function 755
    chmod -R 755 $argv
end
function 777
    chmod -R 777 $argv
end
# Search command line history
function h
    history | grep $argv
end
# Search running processes
function p
    ps aux | grep $argv
end
function topcpu
    /bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10 $argv
end
# Search files in the current folder
function f
    find . | grep $argv
end
# Show open ports
function openports
    netstat -nape --inet $argv
end
# Functions for safe and forced reboots
function rebootsafe
    sudo shutdown -r now $argv
end
function rebootforce
    sudo shutdown -r -n now $argv
end
# Functions to show disk space and space used in a folder
function diskspace
    du -S | sort -n -r | more $argv
end
function folders
    du -h --max-depth=1 $argv
end
function folderssort
    find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn $argv
end
function tree
    tree -CAhF --dirsfirst $argv
end
function treed
    tree -CAFd $argv
end
function mountedinfo
    df -hT $argv
end
# Functions for archives
function mktar
    tar -cvf $argv
end
function mkbz2
    tar -cvjf $argv
end
function mkgz
    tar -cvzf $argv
end
function untar
    tar -xvf $argv
end
function unbz2
    tar -xvjf $argv
end
function ungz
    tar -xvzf $argv
end
