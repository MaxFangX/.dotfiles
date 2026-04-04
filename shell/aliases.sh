# shell/aliases.sh - General aliases and functions (non-git)
# Sourced by shell/common.sh

##############
# Navigation #
##############

cdls() { cd "$@" && ls; }
cdl() { cd "$@" && l; }

################
# File listing #
################

alias ll='ls -alF'
alias la='ls -a'
alias l='ls -CF'
alias ls='ls -GFh'

##########
# Editor #
##########

alias v=nvim
alias vi=nvim
alias vim=nvim
alias vs="nvim -S"

##########
# Search #
##########

alias f=fzf

# Ripgrep
alias rgf="rg --files"
alias rgn="rg --no-ignore"
alias rgfn="rg --files --no-ignore"
alias rgnf="rg --files --no-ignore"
# Emulate Silver Searcher's -g filename search somewhat
function rgg { rg --files | rg "$@"; }
function rggn { rg --files --no-ignore | rg "$@"; }
# To get log/tyche_rCURRENT.log (where log/* is in .gitignore);
# - rggn CURR
# - rgfn | rg CURR
# or just use silver searcher:
# - ag -U -g CURR
# - ag -Ug CURR

#########################
# Python / Django / Pip #
#########################

alias py=python3
alias python=python3
alias rmpyc="find ./ -name '*pyc' | xargs rm -f"
alias rmswp="find ./ -name '*swp' | xargs rm -f"

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
alias pirr="pip3 install -r requirements.txt"
alias pfr="pip3 freeze > requirements.txt"

################
# Rust / Cargo #
################

alias c="cargo"
alias cc="cargo check"
alias cl="cargo clippy"
alias cr="cargo run"
alias crr="cargo run --release"
alias cb="cargo build"
alias cbr="cargo build --release"
alias cf="cargo +nightly-2024-05-03 fmt -- -l"
alias cx="cargo fix --allow-staged --allow-dirty --all-targets"
alias ct="cargo test"
alias cw="cargo watch"
alias cww="cargo watch --why"

########
# Java #
########

alias javat="java org.junit.runner.JUnitCore"
alias javatest="java org.junit.runner.JUnitCore"

###############
# Build tools #
###############

alias j="just"

################
# Shell config #
################

alias resource='exec "$SHELL" -l'
alias to-dotfiles="source ~/.dotfiles/scripts/to-dotfiles.sh"
alias from-dotfiles="source ~/.dotfiles/scripts/from-dotfiles.sh"

# Quickly switch between different environments with $ work <project>
work() { resource && . ~/.dotfiles/scripts/"$@".sh; }

#############
# Utilities #
#############

# thefuck alias
if [ -x "$(command -v thefuck)" ]; then
    eval "$(thefuck --alias)"
fi
# Fix for git push --no-verify over --set-upstream until packages are updated
# https://github.com/nvbn/thefuck/issues/1207#issuecomment-864671223
export THEFUCK_PRIORITY="git_hook_bypass=1100"

wordcount() { find ~/Obsidian/ -type f -name "*.md" -exec cat '{}' \+ | wc -w; }

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

# Strip out ansi characters from a log file: `strip-ansi example.log`
strip-ansi() {
  if [ -f "$1" ]; then
    perl -i -pe 's/\x1B\[(([0-9]{1,2})?(;)?([0-9]{1,2})?)?[m,K,H,f,J]//g' "$1"
    echo "ANSI escape codes have been removed from $1"
  else
    echo "File $1 does not exist."
  fi
}

###############
# Claude Code #
###############

alias claude-foom="claude --dangerously-skip-permissions"
alias claude-go-foom="claude --dangerously-skip-permissions"

########
# Misc #
########

alias sw="sass --watch"
alias ngrok="~/ngrok http 8000 -subdomain=maxfangx"
alias sv="grunt server"
svp() { grunt server --partner=$1; }
alias latexmk='latexmk -pdf -pvc'
alias fucking='sudo'
