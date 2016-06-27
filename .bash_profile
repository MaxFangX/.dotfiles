if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

# Alias definitions. Currently not used
# if [ -f ~/.bash_aliases ]; then
#     . ~/.bash_aliases
# fi

# Some ls aliases
alias ll='ls -alF'
alias la='ls -a'
alias l='ls -CF'
alias ls='ls -GFh'

# Settings and misc aliases
alias py=python3
alias rmpyc="find ./ -name '*pyc' | xargs rm -f"
alias rmswp="find ./ -name '*swp' | xargs rm -f"

# cdls and cdl as commands to change directory and list
cdls() { cd "$@" && ls; }
cdl() { cd "$@" && l; }

# commands to quickly switch between different environments
alias clean="source ~/.vim/clean.sh"
fang() { clean && . ~/scripts/"$@".sh; }
work() { clean && . ~/scripts/"$@".sh; }

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

# usage: gerrit [clone] [project]
gerrit() { git $1 ssh://max@gerrit.sigfig.com:2222/$2; }

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

function gadis { git add "$@"; git diff --staged "$@"; }

alias gch="git checkout"
alias gchm="git checkout master"

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

alias grb="git rebase"
alias grbi="git rebase -i"
alias grbc="git rebase --continue"
alias grbs="git rebase --skip"

alias glo="git log"

alias gbl="git blame"

alias grs="git reset"
alias grsh="git reset HEAD"


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

# Ctags
alias ctagshide="ctags -R -f ./.git/tags"
alias ctagsfull="ctags --links=no --exclude='@.gitignore' -R ."

# Misc
alias sw="sass --watch"
alias ngrok="~/ngrok http 8000 -subdomain=maxfangx"
alias sv="grunt server"
svp() { grunt server --partner=$1; }

# Sensitive environment variables
if [ -f ~/scripts/info.sh ]; then
    . ~/scripts/info.sh
fi

export PATH="/usr/local/sbin:$PATH"

if [ -f ~/scripts/local.sh ]; then
    . ~/scripts/local.sh
fi

# TODO move this into script
export PATH="~/sigfig/ngts/ngts_dev_tools/bin:$PATH"
