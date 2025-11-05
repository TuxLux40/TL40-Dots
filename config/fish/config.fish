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
alias spico 'sudo micro'
alias snano 'sudo micro'
alias vim 'micro'
alias nano 'micro'

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
# Aliases for package managers
# Alias apt-get 'sudo nala'
# Alias apt 'sudo nala'
alias pacman 'sudo pacman --color=always --noconfirm --needed'
alias yay 'yay --color=always --noconfirm --needed'
alias yayf "yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"
alias blupdate 'sudo akshara update'
alias paru 'paru --color=always --noconfirm --needed'
alias dnf 'sudo dnf --color=always -y'
# Miscellaneous aliases
alias cp 'cp -i'
alias mv 'mv -i'
alias rm 'trash -v'
alias mkdir 'mkdir -p'
alias ps 'ps auxf'
alias ping 'ping -c 10'
alias less 'less -R'
alias multitail 'multitail --no-repeat -c'
alias a 'aichat'
alias grep 'ugrep --color=always -T'
alias freshclam 'sudo freshclam'
# Alias's for TUI tools
alias sysctl 'sudo systemctl-tui'
alias stui 'systemctl-tui'
alias blui 'bluetui'
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
