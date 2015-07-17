# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls -GFh'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Settings and misc aliases
alias py=python3
alias rmpyc="find ./ -name '*pyc' | xargs rm -f"

# cdls and cdl as commands to change directory and list
cdls() { cd "$@" && ls; }   
cdl() { cd "$@" && l; }   

# commands to quickly switch between different environments
workon() { . ~/scripts/"$@".sh; }

# PhantomJS
export PATH=$PATH:/home/user/work/phantomjs/bin/

# NodeJs
export PATH=$PATH:/home/user/.nvm/v0.10.38/bin/

# Prevent production server api calls
export CHANGECOIN_API=http://localhost:8000/v1

# Hack for YCM to work
export DYLD_FORCE_FLAT_NAMESPACE=1

# Java
alias javat="java org.junit.runner.JUnitCore"
alias javatest="java org.junit.runner.JUnitCore"

# Git
alias gs="git status"

alias gdi="git diff"
alias gdihh="git diff HEAD^ HEAD"

alias gch="git checkout"
alias gchm="git checkout master"

alias gco="git commit"
alias gcom="git commit -m"
alias gcoam="git commit -a -m"

alias gps="git push"
alias gpso="git push origin"
alias gpsom="git push origin master"

alias gpl="git pull"
alias gplo="git pull origin"
alias gplom="git pull origin master"
alias gplr="git pull --rebase"
alias gplro="git pull --rebase origin"
alias gplrom="git pull --rebase origin master"

alias gme="git merge"
alias gmem="git merge master"

alias gad="git add"

alias gss="git stash"
alias gssa="git stash apply"
alias gssp="git stash pop"

alias grm="git rm"

alias gbr="git branch"
alias gbrr="git branch -r"

alias gre="git rebase"
alias grec="git rebase --continue"
alias gres="git rebase --skip"

alias glo="git log"

# Updates a feature branch
update() {
    git checkout master &&
    git pull origin master &&
    git checkout "$@" &&
    git merge master;
}   

# Python
alias py="python"
alias py3="python3"

# Django
alias pm="python manage.py"
alias p3m="python3 manage.py"

alias pmr="python manage.py runserver"
alias p3mr="python3 manage.py runserver"

alias pms="python manage.py shell"
alias p3ms="python3 manage.py shell"

alias pmt="python manage.py test"
alias p3mt="python3 manage.py test"

alias pmmkm="python manage.py makemigrations"
alias p3mmkm="python3 manage.py makemigrations"

alias pmm="python manage.py migrate"
alias p3mm="python3 manage.py migrate"

alias pmc="python manage.py check"
alias p3mc="python3 manage.py check"

# Pip
alias pirr="pip install -r requirements.txt"
alias pfr="pip freeze > requirements.txt"

# Sensitive environment variables
if [ -f ~/scripts/info.sh ]; then
    . ~/scripts/info.sh
fi

