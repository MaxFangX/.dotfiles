# macOS-specific environment setup.
# Sourced by shell/common.sh on Darwin only.

# User binaries requiring root access
ROOT_BIN_PATH="$(brew --prefix)/sbin"
if [[ ! "$PATH" == *$ROOT_BIN_PATH* ]]; then
  export PATH="$PATH:$ROOT_BIN_PATH"
fi

# Go
export GOPATH=~/gocode
GO_BIN_PATH="$GOPATH/bin"
if [[ ! "$PATH" == *$GOPATH* ]]; then
  export PATH="$PATH:$GOPATH"
fi

# Ruby - chruby
if [ -f $(brew --prefix)/opt/chruby/share/chruby/chruby.sh ]; then
    source $(brew --prefix)/opt/chruby/share/chruby/chruby.sh
fi
# Enable auto-switching of Rubies specified by .ruby-version files
if [ -f $(brew --prefix)/opt/chruby/share/chruby/auto.sh ]; then
    source $(brew --prefix)/opt/chruby/share/chruby/auto.sh
fi
# Use 2.7.2 by default
if [ -x "$(command -v chruby)" ]; then
    chruby ruby-2.7.2
fi

# Ruby - Gem
export GEM_HOME=$HOME/.local/gem
GEM_BIN=$GEM_HOME/bin
if [[ ! "$PATH" == *$GEM_BIN* ]]; then
    export PATH="$PATH:$GEM_BIN"
fi

# Java, Android, and Flutter are now managed by Nix (home/mods/dev-lexe/)

# LM Studio
export LM_STUDIO_BIN="$HOME/.lmstudio/bin"
if [[ ! "$PATH" == *$LM_STUDIO_BIN* ]]; then
    export PATH="$PATH:$LM_STUDIO_BIN"
fi

# Windsurf
export WINDSURF_BIN="$HOME/.codeium/windsurf/bin"
if [[ ! "$PATH" == *$WINDSURF_BIN* ]]; then
    export PATH="$PATH:$WINDSURF_BIN"
fi
