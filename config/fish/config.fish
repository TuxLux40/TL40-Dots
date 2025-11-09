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
alias vim 'micro'
alias nano 'micro'

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

# Check if ripgrep is installed
if command -v rg >/dev/null 2>&1
    # Alias grep to rg if ripgrep is installed
    alias grep='rg'
else
    # Alias grep to /usr/bin/grep with GREP_OPTIONS if ripgrep is not installed
    alias grep="/usr/bin/grep $GREP_OPTIONS"
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
#                 ALIAS'S                  #
############################################
# Alias's to change the directory
alias web 'cd /var/www/html'
alias config 'cd ~/.config'
alias dl 'cd ~/Downloads'
alias docs 'cd ~/Documents'
alias pics 'cd ~/Pictures'
alias vids 'cd ~/Videos'
alias music 'cd ~/Music'
alias desk 'cd ~/Desktop'
alias projects 'cd ~/Projects'
# Edit this fish config file
alias efish 'micro ~/.config/fish/config.fish'
# alias to show the date
alias da 'date "+%Y-%m-%d %A %T %Z"'
# Miscellaneous aliases
alias cp 'cp -i' # Interactive copy
alias mv 'mv -i' # Interactive move
alias rm 'trash -v' # Move to trash
alias mkdir 'mkdir -p' # Create parent directories
alias ps 'ps auxf' # Tree view of processes
alias ping 'ping -c 10' # Ping with count
alias less 'less -R' # Less with raw control chars
alias multitail 'multitail --no-repeat -c' # Multitail with no repeat and color
alias a 'aichat' # AI chat alias
alias grep 'ugrep --color=always -T' # Grep with color and tree view
# Alias's for TUI tools
alias sysctl 'systemctl-tui' # Systemctl TUI alias
alias stui 'systemctl-tui' # Systemctl TUI alias
alias blui 'bluetui' # Bluetui alias
# Change directory aliases
alias home 'cd ~'
alias cd.. 'cd ..'
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
# Remove a directory and all files
alias rmd '/bin/rm  --recursive --force --verbose '
# Alias's for multiple directory listing commands
alias la 'ls -Alh'
alias ls 'ls -aFh --color=always'
alias lx 'ls -lXBh'
alias lk 'ls -lSrh'
alias lc 'ls -ltcrh'
alias lu 'ls -lturh'
alias lr 'ls -lRh'
alias lt 'ls -ltrh'
alias lm 'ls -alh |more'
alias lw 'ls -xAh'
alias ll 'ls -Fls'
alias labc 'ls -lap'
alias lf "ls -l | egrep -v '^d'"
alias ldir "ls -l | egrep '^d'"
alias lla 'ls -Al'
alias las 'ls -A'
alias lls 'ls -l'
# alias chmod commands
alias mx 'chmod a+x'
alias 000 'chmod -R 000'
alias 644 'chmod -R 644'
alias 666 'chmod -R 666'
alias 755 'chmod -R 755'
alias 777 'chmod -R 777'
# Search command line history
alias h 'history | grep '
# Search running processes
alias p 'ps aux | grep '
alias topcpu '/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10'
# Search files in the current folder
alias f 'find . | grep '
# Show open ports
alias openports 'netstat -nape --inet'
# Alias's for safe and forced reboots
alias rebootsafe 'sudo shutdown -r now'
alias rebootforce 'sudo shutdown -r -n now'
# Alias's to show disk space and space used in a folder
alias diskspace 'du -S | sort -n -r |more'
alias folders 'du -h --max-depth=1'
alias folderssort 'find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree 'tree -CAhF --dirsfirst'
alias treed 'tree -CAFd'
alias mountedinfo 'df -hT'
# Alias's for archives
alias mktar 'tar -cvf'
alias mkbz2 'tar -cvjf'
alias mkgz 'tar -cvzf'
alias untar 'tar -xvf'
alias unbz2 'tar -xvjf'
alias ungz 'tar -xvzf'
# alias to cleanup unused podman containers, images, networks, and volumes
function podman-clean
	podman container prune -f
	podman image prune -f
	podman network prune -f
	podman volume prune -f
end
