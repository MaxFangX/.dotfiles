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
alias rmswp="find ./ -name '*swp' | xargs rm -f"

# cdls and cdl as commands to change directory and list
cdls() { cd "$@" && ls; }   
cdl() { cd "$@" && l; }   

# commands to quickly switch between different environments
work() { . ~/scripts/"$@".sh; }

# Easy extract
extract () {
  if [ -f $1 ] ; then
      case $1 in
          *.tar.bz2)   tar xvjf $1    ;;
          *.tar.gz)    tar xvzf $1    ;;
          *.bz2)       bunzip2 $1     ;;
          *.rar)       rar x $1       ;;
          *.gz)        gunzip $1      ;;
          *.tar)       tar xvf $1     ;;
          *.tbz2)      tar xvjf $1    ;;
          *.tgz)       tar xvzf $1    ;;
          *.zip)       unzip $1       ;;
          *.Z)         uncompress $1  ;;
          *.7z)        7z x $1        ;;
          *)           echo "don't know how to extract '$1'..." ;;
      esac
  else
      echo "'$1' is not a valid file!"
  fi
}

# PhantomJS
export PATH=$PATH:/home/user/work/phantomjs/bin

# NodeJs
export PATH=$PATH:/home/user/.nvm/v0.10.38/bin

# Prevent production server api calls
export CHANGECOIN_API=http://localhost:8000/v1

# Hack for YCM to work
export DYLD_FORCE_FLAT_NAMESPACE=1

# Vim
export EDITOR="/usr/local/bin/vim"

# Java
alias javat="java org.junit.runner.JUnitCore"
alias javatest="java org.junit.runner.JUnitCore"

# Git
alias gs="git status"

alias gad="git add"

alias gdi="git diff"
alias gdihh="git diff HEAD^ HEAD"
alias gdis="git diff --staged"

function gadis { git add "$@"; git diff --staged; }   

alias gch="git checkout"
alias gchm="git checkout master"

alias gco="git commit"
alias gcom="git commit -m"
alias gcoam="git commit -a -m"
alias gcoa="git commit --amend"

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

alias gbl="git blame"

alias grs="git reset"
alias grsh="git reset HEAD"

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

alias pmr="python manage.py runserver -v 2"

alias pms="python manage.py shell -v 2"

alias pmt="python manage.py test -v 2"
alias pmtk="python manage.py test -k -v 2"

alias pmmkm="python manage.py makemigrations -v 2"

alias pmm="python manage.py migrate"
alias pmml="python manage.py migrate --list"
alias pmmfi="python manage.py migrate --fake-initial"

alias pmc="python manage.py check -v 2"

# Pip
alias pirr="pip install -r requirements.txt"
alias pfr="pip freeze > requirements.txt"

# Sensitive environment variables
if [ -f ~/scripts/info.sh ]; then
    . ~/scripts/info.sh
fi

# Path to your oh-my-zsh installation.
export ZSH=/Users/fang/.oh-my-zsh

###########################
# ZSH SETTINGS
###########################

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

# User configuration

export PATH="/Users/fang/work/tipenv/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/home/user/work/phantomjs/bin:/home/user/.nvm/v0.10.38/bin:/media/sf_Google_Drive/Programming/Github/aow/proj2/*:/home/user/work/phantomjs/bin:/home/user/.nvm/v0.10.38/bin:/media/sf_Google_Drive/Programming/Github/aow/proj2/*"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"