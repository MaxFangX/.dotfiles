###########################
# GENERAL
###########################

# Increase soft per-process file descriptor limit to 1024
ulimit -Sn 1024

###########################
# ENVIRONMENT VARIABLES
###########################

# Set up and source the device-specific env var files
mkdir -p ~/env
touch ~/env/local.sh ~/env/sensitive.sh
chmod u+x ~/env/local.sh ~/env/sensitive.sh
source ~/env/local.sh
source ~/env/sensitive.sh

# macOS-specific environment (brew, NVM, chruby, etc.)
if [[ "$(uname)" == "Darwin" ]]; then
    source ~/.dotfiles/shell/macos.sh
fi

###########################
# Init
###########################

# Source Nix profile script if nix isn't already available and script exists
if ! command -v nix >/dev/null 2>&1; then
  if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
fi

###########################
# ALIASES
###########################

source ~/.dotfiles/shell/aliases.sh
source ~/.dotfiles/shell/git-aliases.sh
