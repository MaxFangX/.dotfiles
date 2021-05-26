###########################
# System
###########################

# Install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install brew cask
brew tap caskroom/cask

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

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

# YouCompleteMe
# http://www.nyayapati.com/srao/2014/12/installing-homebrew-macvim-with-youcompleteme-on-yosemite/
# requires cmake
# YCM must be install before submodules can be updated
cd ~/.vim/bundle/YouCompleteMe
mkdir YouCompleteMe/ycmbuild
cd ycmbuild
cmake -G "Unix Makefiles" . ~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp
make ycm_core
cd ~/.vim

# Tern for vim https://github.com/ternjs/tern_for_vim
# requires node
cd ~/.vim/bundle/tern_for_vim
npm install
cd ~/.vim

# Install vim powerline fonts
# Instructions here: https://github.com/powerline/fonts
cd ~/.vim
git clone https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd ~/.vim
rm -rf fonts

# Install Vundle plugins
vim +PluginInstall +qall

# Update submodules
cd ~/.vim
git submodule update --init --recursive

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
# Command line tools
###########################

# ZSH
# Instructions here: http://sourabhbajaj.com/mac-setup/iTerm/zsh.html
brew install zsh zsh-completions

# Oh my zsh
# VPN may mess with this
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install thefuck
brew install thefuck

# Install the silver searcher
brew install the_silver_searcher

# Install tldr
brew install tldr

# Tree
brew install tree

# Ripgrep
brew install ripgrep

###########################
# Misc
###########################

# Make a github folder if it doesn't already exist
mkdir -p ~/github

# Clone the repo required for the cputemp alias
git clone https://github.com/lavoiesl/osx-cpu-temp

# Install coreutils required for sha256sum
brew install coreutils
