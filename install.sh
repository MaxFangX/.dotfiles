###########################
# System
###########################

# Install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install brew cask
brew tap caskroom/cask

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update

# Java
brew cask install java

# Install gpg
brew install gpg

# Install ruby
brew install ruby

# Install Cmake so that installing submodules works
brew install cmake

# Install Node
brew install node

# Install Python
brew install python

# Fix Python
# https://stackoverflow.com/questions/47513024/how-to-fix-permissions-on-home-brew-on-macos-high-sierra
sudo mkdir /usr/local/Frameworks
sudo chown $(whoami):admin /usr/local/Frameworks    
brew link python3
# Check python --version is a python3 version

# Install pip and virtualenv
# Might error if on VPN
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py
# Test with pip --version before:
rm get-pip

# Install PostGreSQL
brew install postgresql

###########################
# VIM
###########################

# Tern for vim https://github.com/ternjs/tern_for_vim
# requires node
cd ~/.vim/bundle/tern_for_vim
npm install
cd ~/.vim

# Install vim-plug plugins
vim +PlugInstall

###########################
# Pip dependencies
###########################

# Python linters
pip install pep8
pip install pyflakes
pip install flake8

###########################
# Javascript dependencies
###########################

# Javascript linters
npm install -g jshint

###########################
# Rust / Cargo
###########################

# See installed packages:
cargo install --list

# Cargo watch
cargo install cargo-watch

# Cargo crev
cargo install cargo-crev

###########################
# Command line tools
###########################

# ZSH
# Instructions here: http://sourabhbajaj.com/mac-setup/iTerm/zsh.html
brew install zsh zsh-completions

# Oh my zsh
# VPN may mess with this
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# thefuck
brew install thefuck

# tldr
brew install tldr

# Tree
brew install tree

# Ripgrep
brew install ripgrep

# fzf
brew install fzf
# To install useful key bindings and fuzzy completion:
$(brew --prefix)/opt/fzf/install

###########################
# Misc
###########################

# Make a github folder if it doesn't already exist
mkdir -p ~/github

# Clone the repo required for the cputemp alias
git clone https://github.com/lavoiesl/osx-cpu-temp

# Install coreutils required for sha256sum
brew install coreutils
